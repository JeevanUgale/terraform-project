/**
 * RDS Module - Variables
 */

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"

  validation {
    condition     = length(var.db_name) > 0 && length(var.db_name) <= 64
    error_message = "Database name must be between 1 and 64 characters."
  }
}

variable "db_engine" {
  description = "Database engine (mysql or postgres)"
  type        = string
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "postgres"], var.db_engine)
    error_message = "Database engine must be mysql or postgres."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0.35"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.(t3|t4g|m5|m6i)\\.", var.db_instance_class))
    error_message = "Instance class must be from the approved list."
  }
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be gp2, gp3, io1, or io2."
  }
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "admin"
  sensitive   = true

  validation {
    condition     = length(var.db_username) > 0 && length(var.db_username) <= 16
    error_message = "Username must be between 1 and 16 characters."
  }
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 subnets are required for RDS."
  }
}

variable "security_group_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "backup_window" {
  description = "Backup window in UTC"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "owner" {
  description = "Owner of the project"
  type        = string
  default     = "DevOps Team"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
