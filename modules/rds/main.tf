/**
 * RDS Module - Main Configuration
 * Creates RDS database in private subnets with encryption
 */

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "Terraform"
      Module      = "RDS"
    }
  )

  port = var.db_engine == "mysql" ? 3306 : 5432
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-db-subnet-group-${var.environment}"
    }
  )
}

# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-rds-key-${var.environment}"
    }
  )
}

# KMS Key Alias
resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds-${var.environment}"
  target_key_id = aws_kms_key.rds.key_id
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family      = var.db_engine == "mysql" ? "mysql8.0" : "postgres15"
  name        = "${var.project_name}-db-params-${var.environment}"
  description = "Parameter group for ${var.project_name}"

  # Enable slow query logging for MySQL
  dynamic "parameter" {
    for_each = var.db_engine == "mysql" ? [1] : []
    content {
      name  = "slow_query_log"
      value = "1"
    }
  }

  # Enable query logging for PostgreSQL
  dynamic "parameter" {
    for_each = var.db_engine == "postgres" ? [1] : []
    content {
      name  = "log_statement"
      value = "all"
    }
  }

  tags = local.common_tags
}

# DB Option Group (MySQL only)
resource "aws_db_option_group" "main" {
  count                    = var.db_engine == "mysql" ? 1 : 0
  name                     = "${var.project_name}-db-options-${var.environment}"
  option_group_description = "Option group for ${var.project_name}"
  engine_name              = var.db_engine
  major_engine_version     = regex("^(\\d+)", var.db_engine_version)[0]

  tags = local.common_tags
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier            = "${var.project_name}-db-${var.environment}"
  engine                = var.db_engine
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.allocated_storage
  storage_type          = var.storage_type
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  port                  = local.port
  parameter_group_name  = aws_db_parameter_group.main.name
  option_group_name     = var.db_engine == "mysql" ? aws_db_option_group.main[0].name : null
  db_subnet_group_name  = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  # Security settings
  publicly_accessible       = false
  storage_encrypted         = true
  kms_key_id                = aws_kms_key.rds.arn
  iam_database_authentication_enabled = true

  # Backup settings
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  copy_tags_to_snapshot   = true
  delete_automated_backups = false

  # Maintenance
  maintenance_window          = var.maintenance_window
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  # Multi-AZ
  multi_az = var.multi_az

  # Performance Insights (optional)
  performance_insights_enabled    = false
  # performance_insights_retention_period = 7

  # Enhanced Monitoring
  monitoring_interval = 0
  # monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Disable automatic minor version upgrade in prod
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot-${var.environment}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = var.db_engine == "mysql" ? ["error", "general", "slowquery"] : ["postgresql"]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-db-${var.environment}"
    }
  )

  depends_on = [aws_db_subnet_group.main]
}

# DB Snapshot for backup
resource "aws_db_snapshot" "backup" {
  count              = 0 # Set to 1 if you want to create a snapshot
  db_instance_id     = aws_db_instance.main.id
  db_snapshot_id     = "${var.project_name}-db-snapshot-${var.environment}-${formatdate("YYYY-MM-DD", timestamp())}"
  tags               = local.common_tags
}
