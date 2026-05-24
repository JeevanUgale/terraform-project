# Module Architecture and Design

## Module Overview

This document provides detailed information about each module, their responsibilities, and how they interact.

---

## VPC Module

### Purpose
Creates the network foundation for all AWS resources with proper isolation and routing.

### Key Components
```
VPC
├── Internet Gateway (IGW)
├── Public Subnets (2+)
│   └── NAT Gateway (for private subnet outbound traffic)
├── Private Subnets (2+)
└── Route Tables
    ├── Public RT → IGW
    └── Private RT → NAT Gateway
```

### Input Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_cidr` | string | 10.0.0.0/16 | VPC CIDR block |
| `availability_zones` | list | [us-east-1a, us-east-1b] | AZs for subnets |
| `public_subnet_cidrs` | list | [10.0.1.0/24, ...] | Public subnet CIDRs |
| `private_subnet_cidrs` | list | [10.0.10.0/24, ...] | Private subnet CIDRs |

### Outputs
- `vpc_id`: VPC identifier
- `public_subnet_ids`: List of public subnet IDs
- `private_subnet_ids`: List of private subnet IDs
- `nat_gateway_eip`: NAT Gateway public IP

### Dependencies
- None (root module)

### Security Considerations
- Public subnets only used for load balancers and NAT
- Private subnets for databases and sensitive resources
- Network ACLs for additional security layer
- VPC Flow Logs for traffic monitoring (optional)

---

## Security Groups Module

### Purpose
Implements network-level security with least privilege access control.

### Security Group Rules

#### EC2 Security Group
```
Ingress:
  - SSH (22): From allowed_ssh_cidr
  - HTTP (80): From 0.0.0.0/0 (conditional)
  - HTTPS (443): From 0.0.0.0/0 (conditional)

Egress:
  - All traffic to 0.0.0.0/0
```

#### RDS Security Group
```
Ingress:
  - MySQL/PostgreSQL: From EC2 security group only

Egress:
  - All traffic to 0.0.0.0/0
```

### Input Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_id` | string | - | VPC for security groups |
| `allowed_ssh_cidr` | string | 0.0.0.0/0 | SSH access CIDR |
| `enable_http` | bool | true | Allow HTTP |
| `enable_https` | bool | true | Allow HTTPS |

### Outputs
- `ec2_security_group_id`: EC2 SG ID
- `rds_security_group_id`: RDS SG ID

### Dependencies
- VPC Module

### Security Considerations
- EC2 SG should restrict SSH to known IPs/bastion
- RDS SG uses source SG (not CIDR) for better control
- Regular review of ingress/egress rules
- Remove unnecessary rules

---

## IAM Module

### Purpose
Creates identity and access management policies for EC2 to access other AWS services.

### IAM Components
```
IAM Role (EC2)
├── Trust Relationship: EC2 Service
├── S3 Access Policy
│   ├── ListBucket
│   ├── GetObject
│   ├── PutObject
│   └── DeleteObject
├── CloudWatch Logs Policy
│   ├── CreateLogGroup
│   ├── CreateLogStream
│   ├── PutLogEvents
│   └── DescribeLogStreams
├── CloudWatch Metrics Policy
│   └── PutMetricData
└── Instance Profile

AWS Systems Manager
└── AmazonSSMManagedInstanceCore
```

### Policies

#### S3 Access Policy
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    "arn:aws:s3:::bucket-name",
    "arn:aws:s3:::bucket-name/*"
  ]
}
```

#### CloudWatch Logs Policy
```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": "arn:aws:logs:region:account:log-group:/aws/ec2/*"
}
```

### Input Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `s3_bucket_arn` | string | - | S3 bucket ARN |
| `environment` | string | - | Environment name |

### Outputs
- `ec2_role_arn`: EC2 IAM role ARN
- `instance_profile_name`: Instance profile name
- `s3_policy_arn`: S3 access policy ARN

### Dependencies
- S3 Module (for bucket ARN)

### Security Considerations
- **Least Privilege**: Only permissions needed
- **Resource Specific**: ARNs specify exact resources
- **Conditions**: KMS conditions restrict to S3 service
- **Audit Trail**: IAM changes logged in CloudTrail

---

## EC2 Module

### Purpose
Launches and configures EC2 instance with proper security and monitoring.

### EC2 Configuration
```
EC2 Instance
├── AMI: Amazon Linux 2 (latest)
├── EBS Volume: 20GB, gp3, encrypted
├── Security: IMDSv2 enforced
├── IAM: Instance profile attached
├── Networking: Public subnet, Elastic IP
├── Monitoring: CloudWatch detailed
└── User Data: Instance initialization
```

### Input Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_type` | string | t3.micro | EC2 instance type |
| `key_name` | string | - | EC2 key pair name |
| `subnet_id` | string | - | Public subnet ID |
| `security_group_id` | string | - | Security group ID |
| `iam_instance_profile` | string | - | IAM instance profile |

### User Data Script
The user data script performs:
```bash
1. System updates
2. Tool installation (docker, aws-cli, mysql client)
3. Environment variable configuration
4. S3 access verification
5. RDS connectivity check
6. Application directory setup
```

### Outputs
- `instance_id`: EC2 instance ID
- `private_ip`: Private IP address
- `public_ip`: Public IP address
- `elastic_ip`: Elastic IP address
- `ssh_command`: SSH connection command

### Dependencies
- VPC Module
- Security Groups Module
- IAM Module

### Security Considerations
- **AMI Selection**: Uses latest Amazon Linux 2
- **IMDSv2**: Enforced for metadata security
- **EBS Encryption**: All volumes encrypted
- **IAM Instance Profile**: Minimal required permissions
- **SSH Key**: EC2 key pair for authentication only
- **Monitoring**: CloudWatch detailed monitoring enabled

---

## RDS Module

### Purpose
Manages relational database with encryption, backups, and high availability.

### RDS Components
```
RDS Instance
├── Engine: MySQL or PostgreSQL
├── Encryption: KMS encrypted at rest
├── Backup: Automated daily backups
├── Multi-AZ: Optional high availability
├── Subnet Group: Private subnets only
├── Parameter Group: Database tuning
└── Option Group: Additional features
```

### Database Engines Supported
| Engine | Version | Port | Use Case |
|--------|---------|------|----------|
| MySQL | 8.0.35+ | 3306 | Web apps, traditional |
| PostgreSQL | 15.3+ | 5432 | Advanced, JSON support |

### Input Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `db_engine` | string | mysql | Database engine |
| `db_engine_version` | string | 8.0.35 | Engine version |
| `db_instance_class` | string | db.t3.micro | Instance size |
| `allocated_storage` | number | 20 | Storage in GB |
| `db_username` | string | admin | Admin username |
| `db_password` | string | - | Admin password |
| `multi_az` | bool | false | High availability |

### Backup Configuration
```
Development:
- Retention: 7 days
- Window: 03:00-04:00 UTC
- Auto-backup: Enabled

Production:
- Retention: 30 days
- Window: 02:00-03:00 UTC
- Auto-backup: Enabled
- Multi-AZ: Enabled
```

### Outputs
- `db_instance_endpoint`: Full endpoint with port
- `db_instance_address`: Endpoint hostname only
- `db_instance_port`: Database port
- `db_name`: Database name
- `connection_string`: Application connection string

### Dependencies
- VPC Module (private subnets)
- Security Groups Module (RDS SG)

### Security Considerations
- **Private Placement**: Database in private subnets
- **Encryption**: KMS encryption at rest
- **Access Control**: Security group restricted
- **Backup**: Automated daily backups
- **Audit Logs**: CloudWatch logs enabled
- **No Public Access**: Not accessible from internet

### Performance Tuning
```sql
-- Enable slow query logging
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- Monitor performance
SHOW PROCESSLIST;
SHOW STATUS;
```

---

## S3 Module

### Purpose
Manages secure object storage with versioning and lifecycle policies.

### S3 Features
```
S3 Bucket
├── Versioning: Enabled for recovery
├── Encryption: AES256 or KMS
├── Public Access: Blocked completely
├── Lifecycle: Transition to GLACIER
├── Logging: Access logs (optional)
└── Lifecycle Rules
    ├── Incomplete Uploads: Delete after 7 days
    ├── Old Versions: Transition to GLACIER
    └── Very Old Objects: Expire after 365 days
```

### Input Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bucket_name` | string | - | Bucket name (globally unique) |
| `versioning_enabled` | bool | true | Enable versioning |
| `encryption_enabled` | bool | true | Enable encryption |
| `encryption_algorithm` | string | AES256 | Encryption type |
| `block_public_access` | bool | true | Block public access |

### Lifecycle Policies
```
Rule 1: Transition Non-current Versions
- After 90 days: Move to GLACIER
- After 365 days: Expire

Rule 2: Incomplete Uploads
- Delete after 7 days

Rule 3: Current Versions
- After 90 days: Move to GLACIER
- After 365 days: Expire
```

### Outputs
- `bucket_id`: Bucket name
- `bucket_arn`: Bucket ARN
- `bucket_domain_name`: S3 domain name

### Dependencies
- None (but used by IAM and EC2 modules)

### Security Considerations
- **Encryption**: Default AES256, can use KMS
- **Versioning**: Enabled for data recovery
- **Public Access**: Blocked at bucket level
- **Bucket Policy**: Enforces encryption and SSL
- **Lifecycle**: Cost optimization with GLACIER
- **MFA Delete**: Optional additional protection

### Best Practices
```bash
# List versioned objects
aws s3api list-object-versions \
  --bucket my-bucket

# Restore deleted object
aws s3api get-object \
  --bucket my-bucket \
  --key my-file \
  --version-id VERSIONID \
  restored-file

# Calculate storage costs
aws s3api list-objects-v2 \
  --bucket my-bucket \
  --query 'Contents[].Size' | jq 'add/1024/1024'
```

---

## Module Dependencies Graph

```
┌─────────────┐
│    VPC      │ ─────────────────────────┐
│   Module    │                         │
└─────────────┘                         │
      │                                  │
      │                ┌─────────────────┼──────────────┐
      │                │                 │              │
      ▼                │                 ▼              ▼
┌─────────────────┐    │        ┌──────────────┐  ┌─────────────┐
│  Security       │    │        │    IAM       │  │     EC2     │
│  Groups Module  │◄───┘        │   Module     │  │   Module    │
│                 │             │              │  │             │
└─────────────────┘             └──────────────┘  └─────────────┘
      │                              │                    │
      │                              ▼                    │
      │                        ┌─────────────┐            │
      │                        │    S3       │            │
      │                        │   Module    │◄───────────┘
      │                        └─────────────┘
      │
      ▼
┌─────────────────┐
│     RDS         │
│    Module       │
└─────────────────┘
```

---

## Module Interaction Flow

### Deployment Order

```mermaid
1. VPC Module
   ├─ Creates network foundation
   └─ Outputs: vpc_id, subnet_ids

2. Security Groups Module
   ├─ Uses vpc_id from VPC
   └─ Outputs: sg_ids

3. IAM Module (can run in parallel with SG)
   ├─ Independent of network
   └─ Outputs: role_arn, instance_profile

4. S3 Module (can run in parallel)
   ├─ Independent of network
   └─ Outputs: bucket_arn

5. RDS Module
   ├─ Uses: subnet_ids, rds_sg_id
   └─ Outputs: db_endpoint, db_address

6. EC2 Module
   ├─ Uses: subnet_ids, sg_ids, iam_profile
   └─ Outputs: instance_id, public_ip
```

### Data Flow

```
Terraform Variables
    │
    ├─ Environment-specific (dev/prod)
    ├─ Module inputs
    └─ Module outputs feed other modules
        │
        ├─ VPC outputs → RDS, EC2
        ├─ SG outputs → EC2, RDS
        ├─ IAM outputs → EC2
        ├─ S3 outputs → IAM
        └─ All outputs → Root outputs
            │
            └─ User/Application uses them
```

---

## Module Customization Guide

### Adding New Resources to a Module

```hcl
# Example: Add CloudWatch alarms to EC2 module
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.project_name}-ec2-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}
```

### Adding New Variables

```hcl
# In variables.tf
variable "enable_alarm_email" {
  description = "Enable email notifications for alarms"
  type        = bool
  default     = false

  validation {
    condition     = var.enable_alarm_email == true || var.enable_alarm_email == false
    error_message = "Must be true or false."
  }
}
```

### Adding New Outputs

```hcl
# In outputs.tf
output "alarm_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = try(aws_sns_topic.alerts[0].arn, null)
}
```

---

## Testing Modules Independently

```bash
# Create temporary test directory
mkdir -p test-modules
cd test-modules

# Test VPC module alone
mkdir vpc-test && cd vpc-test

# Create test main.tf
cat > main.tf <<'EOF'
module "vpc" {
  source = "../../modules/vpc"
  
  vpc_cidr             = "10.0.0.0/16"
  environment          = "test"
  project_name         = "test-app"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
EOF

# Test module
terraform init
terraform plan
terraform apply
```

---

## Performance and Optimization

### Module Performance Tips

| Optimization | Impact | Implementation |
|--------------|--------|----------------|
| Parallel resource creation | High | Use `depends_on` wisely |
| Lazy evaluation | Medium | Use `count` for conditional resources |
| State management | Medium | Use remote state for large deployments |
| Module caching | Low | Use `-plugin-dir` for plugin caching |

---

**Last Updated**: 2024
