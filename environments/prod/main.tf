/**
 * Production Environment - Main Configuration
 * Orchestrates all modules for production-grade 3-tier infrastructure
 */

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  environment           = var.environment
  project_name          = var.project_name
  owner                 = var.owner
  enable_nat_gateway    = true
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id             = module.vpc.vpc_id
  environment        = var.environment
  project_name       = var.project_name
  owner              = var.owner
  allowed_ssh_cidr   = var.allowed_ssh_cidr
  enable_http        = true
  enable_https       = true

  tags = local.common_tags

  depends_on = [module.vpc]
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  environment   = var.environment
  project_name  = var.project_name
  owner         = var.owner
  s3_bucket_arn = module.s3.bucket_arn

  tags = local.common_tags
}

# S3 Module (create before RDS to get bucket ARN)
module "s3" {
  source = "../../modules/s3"

  bucket_name            = var.s3_bucket_name
  environment            = var.environment
  project_name           = var.project_name
  owner                  = var.owner
  versioning_enabled     = var.versioning_enabled
  encryption_enabled     = var.encryption_enabled
  encryption_algorithm   = "AES256"
  block_public_access    = true
  enable_lifecycle_rules = var.enable_lifecycle_rules
  transition_days        = 30   # Transition to GLACIER after 30 days in prod
  expiration_days        = 180  # Expire after 180 days in prod

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  environment           = var.environment
  project_name          = var.project_name
  owner                 = var.owner
  db_name               = var.db_name
  db_engine             = var.db_engine
  db_engine_version     = var.db_engine_version
  db_instance_class     = var.db_instance_class
  allocated_storage     = var.allocated_storage
  db_username           = var.db_username
  db_password           = var.db_password
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_id     = module.security_groups.rds_security_group_id
  multi_az              = var.multi_az
  backup_retention_period = false
  skip_final_snapshot      = true
  delete_automated_backups = true

  tags = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  environment             = var.environment
  project_name            = var.project_name
  owner                   = var.owner
  instance_type           = var.instance_type
  subnet_id               = module.vpc.public_subnet_ids[0]
  security_group_id       = module.security_groups.ec2_security_group_id
  iam_instance_profile    = module.iam.instance_profile_name
  key_name                = var.key_name
  root_volume_size        = 30
  root_volume_type        = "gp3"
  enable_monitoring       = true
  user_data              = base64encode(templatefile("${path.module}/user_data.sh", {
    s3_bucket = module.s3.bucket_id
    db_host   = module.rds.db_instance_address
    db_name   = var.db_name
  }))

  tags = local.common_tags

  depends_on = [module.vpc, module.security_groups, module.iam]
}

# CloudWatch Alarms for Production Monitoring
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project_name}-ec2-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = module.ec2.instance_id
  }

  alarm_description = "Alarm when EC2 CPU exceeds 80%"
  alarm_actions     = [] # Add SNS topic ARN here

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }

  alarm_description = "Alarm when RDS CPU exceeds 75%"
  alarm_actions     = [] # Add SNS topic ARN here

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-storage-low-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }

  alarm_description = "Alarm when RDS free storage is below 10 GB"
  alarm_actions     = [] # Add SNS topic ARN here

  tags = local.common_tags
}
