# Production-Grade 3-Tier AWS Infrastructure with Terraform

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Directory Structure](#directory-structure)
4. [Module Descriptions](#module-descriptions)
5. [Deployment Instructions](#deployment-instructions)
6. [Configuration Guide](#configuration-guide)
7. [Security Considerations](#security-considerations)
8. [Best Practices Used](#best-practices-used)
9. [Troubleshooting](#troubleshooting)
10. [CI/CD Integration](#cicd-integration)
11. [Maintenance and Monitoring](#maintenance-and-monitoring)
12. [Cost Optimization](#cost-optimization)

---

## Architecture Overview

This Terraform project creates a production-ready 3-tier AWS infrastructure with the following components:

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS VPC (10.0.0.0/16)                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Public Subnets (AZ1, AZ2)                │   │
│  │  ┌──────────────┐          ┌──────────────┐          │   │
│  │  │ EC2 Instance │          │ NAT Gateway  │          │   │
│  │  │ (Web Tier)   │◄─────────├──────────────┤          │   │
│  │  └──────────────┘          │              │          │   │
│  │         ▲                   └──────────────┘          │   │
│  │         │                           ▲                │   │
│  │  ┌──────────────────┐        ┌──────┴──────┐        │   │
│  │  │ Internet Gateway │        │ EIP         │        │   │
│  │  └──────────────────┘        └─────────────┘        │   │
│  └──────────────────────────────────────────────────────┘   │
│                         ▲                                    │
│                         │                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          Private Subnets (AZ1, AZ2)                   │   │
│  │  ┌──────────────┐          ┌──────────────┐          │   │
│  │  │     RDS      │          │     S3       │          │   │
│  │  │  (DB Tier)   │          │ (Storage)    │          │   │
│  │  │  Multi-AZ    │          │ Encrypted    │          │   │
│  │  │  Encrypted   │          │ Versioned    │          │   │
│  │  └──────────────┘          └──────────────┘          │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Security Groups:                                            │
│  - EC2 SG: SSH (22), HTTP (80), HTTPS (443)                │
│  - RDS SG: MySQL/PostgreSQL (3306/5432) from EC2 SG only   │
└─────────────────────────────────────────────────────────────┘

Components:
├── Tier 1 (Presentation): EC2 Instance in Public Subnet
├── Tier 2 (Application): EC2 Instance + IAM Roles (in this POC)
├── Tier 3 (Data): RDS Database in Private Subnets
└── Storage: S3 Bucket with Encryption & Versioning
```

### Key Features

- **High Availability**: Multi-AZ deployment with redundancy
- **Security**: Least privilege IAM, encrypted data at rest and in transit
- **Scalability**: Modular design for easy scaling
- **Monitoring**: CloudWatch integration for production environment
- **Disaster Recovery**: Automated backups and snapshots
- **Cost Optimization**: Right-sizing of resources per environment

---

## Prerequisites

### Required Software

```bash
# Terraform >= 1.3
terraform --version

# AWS CLI >= 2.0
aws --version

# Configured AWS credentials
aws configure
```

### AWS Account Requirements

1. **AWS Account** with appropriate IAM permissions
2. **EC2 Key Pair** created in your desired region
3. **S3 Bucket** (optional) for remote state management
4. **Minimum IAM Permissions**:
   - EC2, VPC, RDS, S3, IAM, CloudWatch
   - KMS for encryption
   - CloudFormation (for backend setup)

### AWS Credentials Setup

```bash
# Option 1: AWS CLI Configuration
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region, Output Format

# Option 2: Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: AWS Profiles
aws configure --profile prod
export AWS_PROFILE=prod
```

---

## Directory Structure

```
terraform-project/
│
├── environments/
│   ├── dev/
│   │   ├── main.tf              # Development main configuration
│   │   ├── variables.tf          # Development variables
│   │   ├── outputs.tf            # Development outputs
│   │   ├── provider.tf           # AWS provider configuration
│   │   ├── terraform.tfvars      # Development variable values
│   │   └── user_data.sh          # EC2 initialization script
│   │
│   └── prod/
│       ├── main.tf              # Production main configuration
│       ├── variables.tf          # Production variables
│       ├── outputs.tf            # Production outputs
│       ├── provider.tf           # AWS provider configuration
│       ├── terraform.tfvars      # Production variable values
│       └── user_data.sh          # EC2 initialization script
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf              # VPC, subnets, gateways
│   │   ├── variables.tf          # VPC module variables
│   │   └── outputs.tf            # VPC module outputs
│   │
│   ├── security-groups/
│   │   ├── main.tf              # Security group rules
│   │   ├── variables.tf          # Security group variables
│   │   └── outputs.tf            # Security group outputs
│   │
│   ├── ec2/
│   │   ├── main.tf              # EC2 instance configuration
│   │   ├── variables.tf          # EC2 variables
│   │   ├── user_data.sh          # User data script
│   │   └── outputs.tf            # EC2 outputs
│   │
│   ├── rds/
│   │   ├── main.tf              # RDS database configuration
│   │   ├── variables.tf          # RDS variables
│   │   └── outputs.tf            # RDS outputs
│   │
│   ├── s3/
│   │   ├── main.tf              # S3 bucket configuration
│   │   ├── variables.tf          # S3 variables
│   │   └── outputs.tf            # S3 outputs
│   │
│   └── iam/
│       ├── main.tf              # IAM roles and policies
│       ├── variables.tf          # IAM variables
│       └── outputs.tf            # IAM outputs
│
├── backend/
│   └── backend.tf               # Remote state configuration
│
├── versions.tf                  # Terraform and provider versions
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
```

---

## Module Descriptions

### 1. VPC Module

**Purpose**: Network foundation with public/private subnets, gateways, and routing

**Key Resources**:
- VPC with configurable CIDR
- Public subnets with NAT Gateway for outbound traffic
- Private subnets for databases
- Internet Gateway for public access
- Route tables and associations
- Network ACLs for additional security

**Configuration**:
```hcl
module "vpc" {
  source = "../../modules/vpc"
  
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}
```

### 2. Security Groups Module

**Purpose**: Network access control with principle of least privilege

**Key Resources**:
- EC2 Security Group (SSH, HTTP, HTTPS)
- RDS Security Group (database port only from EC2)
- Ingress and egress rules
- Security group dependencies

**Security Rules**:
```
EC2 SG:
  Ingress:
    - SSH (22): Configurable CIDR
    - HTTP (80): 0.0.0.0/0 (optional)
    - HTTPS (443): 0.0.0.0/0 (optional)
  Egress:
    - All traffic

RDS SG:
  Ingress:
    - MySQL/PostgreSQL: Only from EC2 SG
  Egress:
    - All traffic
```

### 3. IAM Module

**Purpose**: Identity and access management for secure resource access

**Key Resources**:
- EC2 IAM Role with trust relationship
- S3 access policy (GetObject, PutObject, DeleteObject)
- CloudWatch Logs policy for application monitoring
- AWS Systems Manager (Session Manager) policy
- Instance Profile for EC2

**Permissions Granted**:
- S3: List bucket, Get/Put/Delete objects
- CloudWatch: Write logs and metrics
- Systems Manager: Session Manager access
- KMS: Decrypt/Encrypt for S3

### 4. EC2 Module

**Purpose**: Compute instance with security hardening and monitoring

**Key Resources**:
- EC2 instance (Amazon Linux 2 - latest)
- Elastic IP for static public IP
- EBS volume encryption
- IAM instance profile attachment
- CloudWatch detailed monitoring
- IMDSv2 enforcement for security
- User data for initialization

**Instance Configuration**:
- Security: Encrypted EBS, IMDSv2, security group
- Monitoring: CloudWatch detailed monitoring
- Initialization: User data script for setup

### 5. RDS Module

**Purpose**: Managed relational database with high availability

**Key Resources**:
- RDS instance (MySQL or PostgreSQL)
- DB subnet group in private subnets
- Parameter and option groups
- KMS key for encryption
- Backup configuration
- Multi-AZ support

**Database Security**:
- Encryption at rest with KMS
- Private subnet placement
- Security group restriction
- No public accessibility
- Automated backups
- Enhanced monitoring

### 6. S3 Module

**Purpose**: Secure object storage with versioning and lifecycle management

**Key Resources**:
- S3 bucket
- Versioning enabled
- Encryption (AES256 or KMS)
- Block Public Access enabled
- Lifecycle rules for cost optimization
- Bucket policies for security
- Access logging (optional)

**Storage Security**:
- Encryption at rest
- Versioning for recovery
- Lifecycle management (GLACIER transition)
- Public access blocked
- Secure transport enforced
- Incomplete upload cleanup

---

## Deployment Instructions

### Step 1: Prepare Your Environment

```bash
# Clone or navigate to the project
cd terraform-project/environments/dev

# Verify AWS credentials
aws sts get-caller-identity
# Output should show your account ID, user ARN, etc.

# Verify Terraform installation
terraform version
```

### Step 2: Create EC2 Key Pair (if not exists)

```bash
# Generate EC2 key pair
aws ec2 create-key-pair \
    --key-name dev-key \
    --region us-east-1 \
    --query 'KeyMaterial' \
    --output text > dev-key.pem

# Set proper permissions
chmod 400 dev-key.pem

# For production
aws ec2 create-key-pair \
    --key-name prod-key \
    --region us-east-1 \
    --query 'KeyMaterial' \
    --output text > prod-key.pem

chmod 400 prod-key.pem
```

### Step 3: Update Configuration Files

```bash
# Edit terraform.tfvars with your values
vim terraform.tfvars

# Key changes needed:
# - key_name: Change to your EC2 key pair name
# - s3_bucket_name: Change to a globally unique name
# - db_password: Change to a strong password
# - allowed_ssh_cidr: Restrict to your IP in production
```

### Step 4: Initialize Terraform

```bash
# Download provider plugins and modules
terraform init

# Output:
# Terraform has been successfully configured!
```

### Step 5: Plan Deployment

```bash
# Generate execution plan
terraform plan -out=tfplan

# Review the output for:
# - Number of resources to create
# - Resource types and configurations
# - Any potential issues

# Save plan for later reference
terraform show -json tfplan > tfplan.json
```

### Step 6: Apply Configuration

```bash
# For development (with automatic approval)
terraform apply -auto-approve

# For production (requires manual approval)
terraform apply tfplan

# Review outputs:
# - VPC ID
# - EC2 public IP
# - RDS endpoint
# - S3 bucket name
```

### Step 7: Verify Deployment

```bash
# Get outputs
terraform output

# Test EC2 access
ssh -i dev-key.pem ec2-user@<EC2_PUBLIC_IP>

# Check S3 bucket
aws s3 ls s3://your-bucket-name/

# Verify RDS connectivity
mysql -h <RDS_ENDPOINT> -u admin -p

# Check security groups
aws ec2 describe-security-groups --region us-east-1
```

---

## Configuration Guide

### Development Environment (dev)

**File**: `environments/dev/terraform.tfvars`

```hcl
# Cost-optimized configuration
instance_type               = "t3.micro"
db_instance_class          = "db.t3.micro"
allocated_storage          = 20
backup_retention_period    = 7
multi_az                   = false
allowed_ssh_cidr           = "0.0.0.0/0"  # Restrict in production
```

### Production Environment (prod)

**File**: `environments/prod/terraform.tfvars`

```hcl
# High-availability configuration
instance_type              = "t3.small"
db_instance_class         = "db.t3.small"
allocated_storage         = 100
backup_retention_period   = 30
multi_az                  = true
allowed_ssh_cidr          = "10.1.0.0/16"  # Restricted to VPC
```

### Key Configuration Parameters

| Parameter | Dev | Prod | Purpose |
|-----------|-----|------|---------|
| `instance_type` | t3.micro | t3.small | EC2 compute power |
| `db_instance_class` | db.t3.micro | db.t3.small | RDS performance |
| `allocated_storage` | 20 GB | 100 GB | Database size |
| `backup_retention` | 7 days | 30 days | Data retention |
| `multi_az` | false | true | High availability |
| `enable_monitoring` | true | true | CloudWatch metrics |

---

## Security Considerations

### 1. Network Security

**VPC Segmentation**:
- Public subnets: EC2 with internet access
- Private subnets: RDS database (no internet)
- NAT Gateway: Controlled outbound access

**Security Groups**:
```
EC2 Security Group:
  ├─ SSH (22): Restricted CIDR
  ├─ HTTP (80): Open to 0.0.0.0/0
  └─ HTTPS (443): Open to 0.0.0.0/0

RDS Security Group:
  └─ MySQL/PostgreSQL: Only from EC2 SG
```

### 2. Data Protection

**Encryption**:
- **At Rest**: 
  - S3: AES256 (can upgrade to KMS)
  - RDS: KMS encryption enabled
  - EBS: Encryption enabled
- **In Transit**:
  - SSL/TLS for RDS connections
  - VPC endpoints for S3 (optional)

**Secrets Management**:
```bash
# Store sensitive values safely
# Option 1: AWS Secrets Manager
aws secretsmanager create-secret \
  --name prod/database/password \
  --secret-string "YourSecurePassword123!"

# Option 2: HashiCorp Vault
# Option 3: Parameter Store with encryption
```

### 3. Access Control

**IAM Best Practices**:
- Least privilege: Only required permissions
- Role-based access: EC2 → S3, EC2 → CloudWatch
- Policy conditions: Resource-specific restrictions

**SSH Access**:
```bash
# Production: Restrict to bastion/VPN only
allowed_ssh_cidr = "10.1.0.0/16"  # VPC CIDR

# Development: Can be 0.0.0.0/0 temporarily
allowed_ssh_cidr = "0.0.0.0/0"    # For testing only
```

### 4. Audit and Compliance

**Enable Logging**:
```bash
# CloudTrail for API logging
aws cloudtrail create-trail \
  --name org-trail \
  --s3-bucket-name my-bucket

# VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-12345678
```

### 5. Backup and Disaster Recovery

**RDS Backups**:
- Automated daily backups
- 7 days retention (dev), 30 days (prod)
- Manual snapshots for critical points

**S3 Lifecycle**:
- 90 days: Transition to GLACIER
- 365 days: Expiration

---

## Best Practices Used

### 1. Infrastructure as Code

✅ **Implemented**:
- Version-controlled Terraform code
- Modular, reusable components
- Environment separation (dev/prod)
- Consistent naming conventions

### 2. Code Organization

✅ **Implemented**:
- Clear directory structure
- Logical module separation
- Variables, outputs, and main files separated
- Comprehensive comments

### 3. Variable Management

✅ **Implemented**:
- Input variables with validations
- Output variables for cross-module reference
- Local variables for computed values
- Environment-specific tfvars files

### 4. Naming Conventions

```
Resource naming pattern:
{project_name}-{resource_type}-{environment}

Examples:
- 3-tier-app-ec2-dev
- 3-tier-app-rds-prod
- 3-tier-app-s3-bucket-dev
```

### 5. Tagging Strategy

```hcl
common_tags = {
  Environment = var.environment
  Project     = var.project_name
  Owner       = var.owner
  ManagedBy   = "Terraform"
  CostCenter  = var.cost_center
}
```

### 6. State Management

**Current**: Local state (`.terraform/terraform.tfstate`)

**Recommended for Production**:
```hcl
backend "s3" {
  bucket         = "terraform-state-bucket"
  key            = "prod/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

### 7. Error Handling

✅ **Implemented**:
- Variable validations
- Proper dependencies between modules
- Conditional resource creation
- Graceful error messages

### 8. Documentation

✅ **Implemented**:
- README with comprehensive guide
- Module descriptions
- Variable descriptions
- Inline code comments

---

## Terraform Workflow

### Standard Workflow

```bash
# 1. Initialize (once per workspace)
cd environments/dev
terraform init

# 2. Plan (review changes)
terraform plan -out=tfplan

# 3. Apply (deploy resources)
terraform apply tfplan

# 4. Verify
terraform output

# 5. Update (make changes)
# Edit variables/configuration

# 6. Plan again
terraform plan -out=tfplan_update

# 7. Apply updates
terraform apply tfplan_update

# 8. Destroy (when done)
terraform destroy
```

### Useful Terraform Commands

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Show current state
terraform show

# Inspect specific resource
terraform state show module.vpc.aws_vpc.main

# List resources
terraform state list

# Taint resource (force recreation)
terraform taint module.ec2.aws_instance.main

# Untaint resource
terraform untaint module.ec2.aws_instance.main

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Show graph
terraform graph | dot -Tsvg > graph.svg
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. **AWS Credentials Not Found**

```bash
# Error:
# Error: Unable to locate credentials

# Solution:
aws configure
# or
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

#### 2. **Key Pair Not Found**

```bash
# Error:
# Error creating instance: InvalidKeyPair.NotFound

# Solution:
aws ec2 create-key-pair --key-name dev-key --region us-east-1
```

#### 3. **S3 Bucket Already Exists**

```bash
# Error:
# InvalidBucketName

# Solution:
# S3 bucket names are globally unique
# Change the bucket name in terraform.tfvars
s3_bucket_name = "3-tier-app-bucket-dev-12345-unique"
```

#### 4. **VPC Limit Exceeded**

```bash
# Error:
# Service Quota Exceeded: VPC

# Solution:
# Check current VPC count
aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs | length(@)'

# Destroy test environments
terraform destroy
```

#### 5. **RDS Password Issues**

```bash
# Error:
# Password failed validation

# Requirements:
# - 8+ characters
# - Mixed case letters
# - Numbers and special characters

# Example strong password:
db_password = "MySecurePass123!"
```

#### 6. **Module Source Not Found**

```bash
# Error:
# module not found

# Solution:
terraform init -upgrade
terraform get -update
```

### Debugging Commands

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log

# View detailed logs
tail -f /tmp/terraform.log

# Show all resources
terraform state list

# Show specific resource details
terraform state show module.rds.aws_db_instance.main

# Validate all configurations
terraform validate

# Check for issues
terraform fmt -check -recursive
```

---

## CI/CD Integration

### GitHub Actions Integration

**File**: `.github/workflows/terraform.yml`

```yaml
name: Terraform CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.3
      
      - name: Terraform Format
        run: terraform fmt -check -recursive
      
      - name: Terraform Init
        run: |
          cd environments/dev
          terraform init
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Terraform Plan
        run: |
          cd environments/dev
          terraform plan -out=tfplan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Terraform Apply (main branch only)
        if: github.ref == 'refs/heads/main'
        run: |
          cd environments/dev
          terraform apply -auto-approve tfplan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Jenkins Integration

**Jenkinsfile**:

```groovy
pipeline {
    agent any
    
    environment {
        AWS_CREDENTIALS = credentials('aws-credentials')
        ENVIRONMENT = 'dev'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-repo/terraform-project.git'
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh '''
                    cd environments/${ENVIRONMENT}
                    terraform init
                '''
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh '''
                    cd environments/${ENVIRONMENT}
                    terraform plan -out=tfplan
                '''
            }
        }
        
        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    cd environments/${ENVIRONMENT}
                    terraform apply -auto-approve tfplan
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

### Pre-deployment Checklist

```bash
# Automated pre-deployment validation
#!/bin/bash

echo "=== Terraform Pre-Deployment Checklist ==="

# 1. Format check
echo "✓ Checking Terraform format..."
terraform fmt -check -recursive

# 2. Syntax validation
echo "✓ Validating syntax..."
terraform validate

# 3. Security scan (using tfsec)
echo "✓ Running security scan..."
tfsec -r .

# 4. Cost estimation (using terraform cost)
echo "✓ Estimating costs..."
terraform plan -json | terraform-cost-estimate

echo "✓ Pre-deployment checks passed!"
```

---

## Maintenance and Monitoring

### CloudWatch Monitoring

**Metrics Monitored** (Production only):
- EC2 CPU Utilization
- EC2 Memory Usage
- RDS CPU Utilization
- RDS Storage Space
- RDS Database Connections
- S3 Bucket Size

**CloudWatch Alarms**:
```hcl
# EC2 CPU > 80%
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "3-tier-app-ec2-cpu-high-prod"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
}

# RDS CPU > 75%
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "3-tier-app-rds-cpu-high-prod"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 75
}
```

### Health Checks

```bash
# EC2 Health Check
curl http://<EC2_IP>/health

# RDS Connectivity
mysql -h <RDS_ENDPOINT> -u admin -e "SELECT 1;"

# S3 Access
aws s3 ls s3://your-bucket/
```

### Regular Maintenance Tasks

```bash
# Weekly
- Review CloudWatch metrics
- Check backup status
- Verify security group rules

# Monthly
- Review IAM policies
- Update documentation
- Test disaster recovery

# Quarterly
- Security audit
- Cost optimization review
- Performance tuning
```

### Backup Verification

```bash
# List RDS snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier 3-tier-app-db-dev

# Verify S3 versioning
aws s3api get-bucket-versioning \
  --bucket your-bucket-name

# Check backup size
aws rds describe-db-instances \
  --db-instance-identifier 3-tier-app-db-dev
```

---

## Cost Optimization

### Development Environment Optimizations

```hcl
# Use smaller instances
instance_type       = "t3.micro"        # ~$7/month
db_instance_class   = "db.t3.micro"     # ~$24/month

# Reduced backups
backup_retention_period = 7              # 7 days

# No Multi-AZ
multi_az = false                         # Cost saving

# Auto-shutdown (optional)
resource "aws_autoscaling_schedule" "stop_dev" {
  scheduled_action_name  = "stop-dev-instances"
  min_size              = 0
  max_size              = 0
  desired_capacity      = 0
  recurrence            = "0 20 * * *"  # Stop at 8 PM
}
```

### Cost Analysis

```bash
# Estimate costs before applying
terraform plan -json | \
  terraform cost estimate

# Analyze current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "BlendedCost"
```

### Cost Reduction Strategies

| Strategy | Dev | Prod |
|----------|-----|------|
| Spot Instances | ✓ | × |
| Reserved Instances | × | ✓ |
| Auto-scaling | ✓ | ✓ |
| Scheduled shutdown | ✓ | × |
| Right-sizing | ✓ | ✓ |
| S3 Intelligent-Tiering | ✓ | ✓ |

---

## Next Steps and Recommendations

### Immediate Next Steps

1. **Deploy Dev Environment**:
   ```bash
   cd environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

2. **Configure S3 Bucket Name**: Ensure globally unique name

3. **Create EC2 Key Pair**: Required for SSH access

4. **Update Passwords**: Use AWS Secrets Manager

### Recommended Enhancements

1. **Auto Scaling**:
   - Add Auto Scaling Groups
   - Implement load balancing

2. **Logging and Monitoring**:
   - Implement ELK stack
   - Set up log aggregation
   - Create custom CloudWatch dashboards

3. **CI/CD Pipeline**:
   - Set up GitHub Actions
   - Implement automated testing
   - Add approval workflows

4. **Disaster Recovery**:
   - Cross-region replication
   - RDS read replicas
   - Automated failover

5. **Security Hardening**:
   - AWS WAF for web tier
   - VPN/Bastion host for SSH
   - Secrets rotation automation

6. **Cost Optimization**:
   - Reserved Instances for prod
   - Spot instances for dev
   - S3 Intelligent-Tiering

---

## Support and Resources

### Documentation
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS Best Practices](https://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html)

### Tools
- [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform Docs Generator](https://terraform-docs.io/)

### Community
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform)
- [AWS Forums](https://forums.aws.amazon.com/)
- [Stack Overflow: Terraform](https://stackoverflow.com/questions/tagged/terraform)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024 | Initial release - 3-tier infrastructure |

---

## License

This project is licensed under the MIT License.

---

## Authors

- **DevOps Team** - Infrastructure Development

---

## Support

For issues, questions, or contributions:
1. Check the troubleshooting section
2. Review the module documentation
3. Consult AWS documentation
4. Contact DevOps Team

---

**Last Updated**: 2024
**Terraform Version**: >= 1.3
**AWS Provider Version**: ~> 5.0
