# Advanced Deployment Guide

## Remote State Management Setup

### Create S3 Bucket for Terraform State

```bash
#!/bin/bash
# Create remote state infrastructure

BUCKET_NAME="terraform-state-bucket-$(date +%s)"
REGION="us-east-1"

echo "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION

echo "Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

echo "Enabling encryption..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "Blocking public access..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

echo "Configuration:"
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo "Bucket ARN: arn:aws:s3:::$BUCKET_NAME"
```

### Configure Backend

**File**: `versions.tf`

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-xxx"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Migrate from Local State

```bash
# Initialize with remote backend
terraform init

# When prompted, confirm migration
# Type: yes

# Verify migration
terraform state list

# Check S3 bucket
aws s3 ls s3://terraform-state-bucket-xxx/
```

---

## Database Setup and Configuration

### Initial Database Setup

After RDS deployment:

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_address)
DB_USER=$(terraform output -raw rds_username)
DB_PASSWORD="your-secure-password"

# Connect to database
mysql -h $RDS_ENDPOINT -u $DB_USER -p$DB_PASSWORD

# Create application database
CREATE DATABASE app_production;
USE app_production;

# Create sample tables
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

# Grant application user permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON app_production.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
```

### PostgreSQL Initialization

```bash
# For PostgreSQL
PGPASSWORD="your-password" psql -h $RDS_ENDPOINT \
  -U postgres -c "CREATE DATABASE app_production;"

# Create extension
PGPASSWORD="your-password" psql -h $RDS_ENDPOINT \
  -U postgres \
  -d app_production \
  -c "CREATE EXTENSION pg_stat_statements;"
```

---

## EC2 Instance Post-Deployment

### Connect to EC2

```bash
# Get EC2 public IP
EC2_IP=$(terraform output -raw ec2_public_ip)

# SSH into instance
ssh -i dev-key.pem ec2-user@$EC2_IP

# Or using the SSH command from outputs
eval "$(terraform output -raw ec2_ssh_command)"
```

### Initialize Application Environment

```bash
# After SSH connection
cd /opt/app

# Clone application repository
git clone https://github.com/your-org/your-app.git

# Install application dependencies
cd your-app
pip install -r requirements.txt  # Python
npm install                       # Node.js
mvn install                      # Java

# Configure environment
export DB_HOST=$(echo $DB_HOST_VAR)
export S3_BUCKET=$(echo $S3_BUCKET_VAR)

# Run application
./start.sh
```

### Monitor Application Logs

```bash
# View user data execution logs
tail -f /var/log/user-data.log

# View application logs
tail -f /opt/app/application.log

# View system logs
journalctl -f -u docker

# Check Docker containers
docker ps
```

---

## Scaling and Updating Infrastructure

### Adding EC2 Instances

```hcl
# Update variables.tf
variable "number_of_instances" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1
}

# Update main.tf
resource "aws_instance" "web" {
  count = var.number_of_instances
  
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  
  # ... rest of configuration
}

# Update load balancer target group
resource "aws_lb_target_group_attachment" "web" {
  count            = var.number_of_instances
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
```

### Scaling RDS

```bash
# Modify instance class
aws rds modify-db-instance \
  --db-instance-identifier 3-tier-app-db-prod \
  --db-instance-class db.t3.large \
  --apply-immediately

# Increase storage
aws rds modify-db-instance \
  --db-instance-identifier 3-tier-app-db-prod \
  --allocated-storage 200 \
  --apply-immediately
```

---

## Disaster Recovery and Backup

### Automated Backup Strategy

```bash
# Enable automated backups
aws rds modify-db-instance \
  --db-instance-identifier 3-tier-app-db-prod \
  --backup-retention-period 30 \
  --preferred-backup-window "03:00-04:00"

# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier 3-tier-app-db-prod \
  --db-snapshot-identifier prod-backup-$(date +%Y%m%d)

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier 3-tier-app-db-prod
```

### Restore from Snapshot

```bash
# Restore RDS from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier 3-tier-app-db-prod-restored \
  --db-snapshot-identifier prod-backup-20240101

# Restore S3 object version
aws s3api get-object \
  --bucket my-bucket \
  --key my-file.txt \
  --version-id "version-id" \
  restored-file.txt
```

### Cross-Region Backup

```hcl
# Create read replica in different region
resource "aws_db_instance" "replica" {
  identifier            = "3-tier-app-db-prod-replica"
  replicate_source_db   = aws_db_instance.main.identifier
  skip_final_snapshot   = false
  availability_zone     = "us-west-2a"

  tags = merge(local.common_tags, {
    Name = "3-tier-app-db-prod-replica"
  })
}
```

---

## Security Hardening

### VPC Security Enhancement

```hcl
# VPC Endpoint for S3 (avoid NAT charges)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"

  route_table_ids = [aws_route_table.private[*].id]
}

# VPC Endpoint for DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.dynamodb"
}
```

### Network ACL Rules

```hcl
# Additional security with NACLs
resource "aws_network_acl_rule" "public_ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private_mysql" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 3306
  to_port        = 3306
}
```

### Bastion Host Setup

```bash
# Create bastion host in public subnet
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name

  tags = merge(local.common_tags, {
    Name = "bastion-host"
  })
}

# Bastion security group
resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## Performance Optimization

### RDS Performance Insights

```bash
# Enable Performance Insights
aws rds modify-db-instance \
  --db-instance-identifier 3-tier-app-db-prod \
  --enable-performance-insights-on-blue-green \
  --performance-insights-retention-period 7
```

### CloudWatch Dashboard

```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "3-tier-app-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}
```

---

## Troubleshooting Guide

### Network Connectivity Issues

```bash
# Test security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Test route tables
aws ec2 describe-route-tables --route-table-ids rtb-xxxxx

# Check NAT Gateway status
aws ec2 describe-nat-gateways

# Test ping (ICMP)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol icmp \
  --port -1 \
  --cidr 0.0.0.0/0
```

### Database Connection Issues

```bash
# Check RDS instance status
aws rds describe-db-instances \
  --db-instance-identifier 3-tier-app-db-prod

# Check security group
aws rds describe-db-instances \
  --query 'DBInstances[0].VpcSecurityGroups'

# Check parameter groups
aws rds describe-db-parameters \
  --db-parameter-group-name default.mysql8.0

# Enable slow query log
aws rds modify-db-parameter-group \
  --db-parameter-group-name custom-mysql \
  --parameters 'ParameterName=slow_query_log,ParameterValue=1,ApplyMethod=immediate'
```

### S3 Access Issues

```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket my-bucket

# Check CORS
aws s3api get-bucket-cors --bucket my-bucket

# Check encryption
aws s3api get-bucket-encryption --bucket my-bucket

# Test object access
aws s3 cp test-file.txt s3://my-bucket/
```

---

## Cost Management

### Budget Alerts

```bash
# Set up AWS Budgets
aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

### Cost Allocation Tags

```hcl
# Add cost allocation tags
tags = merge(local.common_tags, {
  CostCenter    = "Engineering"
  Department    = "Infrastructure"
  BillingAlert  = "true"
  ChargebackId  = "CC-123"
})
```

### Reserved Instance Planning

```bash
# Analyze RI recommendations
aws ce get-reservation-purchase-recommendation \
  --service "Amazon Elastic Compute Cloud - Compute"

# Purchase Reserved Instance
aws ec2 purchase-reserved-instances-offering \
  --reserved-instances-offering-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
  --instance-count 1
```

---

## Advanced Topics

### Terraform Modules Registry

```bash
# Publish module to Terraform Registry
cd terraform-module
git tag v1.0.0
git push origin v1.0.0

# Use module from registry
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

### Testing Terraform Code

```bash
# Using Terratest (Go testing framework)
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraform(t *testing.T) {
    options := &terraform.Options{
        TerraformDir: "../",
    }
    
    defer terraform.Destroy(t, options)
    terraform.InitAndApply(t, options)
    
    // Assertions
}
```

### Policy as Code with Sentinel

```hcl
# sentinel.hcl
policy "ec2_instance_type" {
  enforcement_level = "mandatory"
}

# ec2_instance_type.sentinel
import "tfplan/v2" as tfplan

allowed_types = ["t3.micro", "t3.small", "t3.medium"]

main = rule {
  all tfplan.resource_changes.aws_instance as _, instances {
    all instances as _, instance {
      instance.change.after.instance_type in allowed_types
    }
  }
}
```

---

## Maintenance Scripts

### Weekly Maintenance Script

```bash
#!/bin/bash
# weekly-maintenance.sh

echo "=== Weekly Terraform Maintenance ==="

# 1. Check for updates
echo "Checking for provider updates..."
terraform providers

# 2. Validate configurations
echo "Validating configurations..."
terraform validate

# 3. Format check
echo "Checking format..."
terraform fmt -check -recursive

# 4. Plan for changes
echo "Planning deployment..."
terraform plan -out=weekly-plan

# 5. Review and commit
echo "Review changes above. Commit if necessary."
```

### Backup Script

```bash
#!/bin/bash
# backup-terraform.sh

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup state files
cp *.tfstate* $BACKUP_DIR/

# Backup configuration
tar -czf $BACKUP_DIR/terraform-config.tar.gz .

# Backup RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier 3-tier-app-db \
  --db-snapshot-identifier backup-$(date +%Y%m%d_%H%M%S)

# Backup S3
aws s3 sync s3://my-bucket $BACKUP_DIR/s3-backup

echo "Backup completed: $BACKUP_DIR"
```

---

## Quick Reference

### Common Commands

| Task | Command |
|------|---------|
| Initialize | `terraform init` |
| Validate | `terraform validate` |
| Format | `terraform fmt -recursive` |
| Plan | `terraform plan -out=tfplan` |
| Apply | `terraform apply tfplan` |
| Destroy | `terraform destroy` |
| Show State | `terraform show` |
| List Resources | `terraform state list` |
| Refresh State | `terraform refresh` |
| Taint Resource | `terraform taint <resource>` |

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `TF_LOG` | Enable debug logging |
| `TF_LOG_PATH` | Log file path |
| `TF_INPUT` | Disable input prompts |
| `TF_CLI_ARGS` | Default CLI arguments |
| `AWS_PROFILE` | AWS profile to use |

---

## Additional Resources

- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Terraform Registry](https://registry.terraform.io/)

---

**Last Updated**: 2024
