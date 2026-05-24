/**
 * Production Environment - Variables
 */

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "3-tier-app"
}

variable "owner" {
  description = "Project owner"
  type        = string
  default     = "DevOps Team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# VPC Variables
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones (use 3 for high availability)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "prod-key" # Change to your key pair name
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (restricted for production)"
  type        = string
  default     = "10.1.0.0/16" # Restrict to VPC CIDR in production
}

# RDS Variables
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.3"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = 100
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true

  # Use terraform.tfvars for this value
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "proddb"
}

variable "backup_retention_period" {
  description = "RDS backup retention days"
  type        = number
  default     = 30
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

# S3 Variables
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "3-tier-app-bucket-prod" # Change to a globally unique name

  validation {
    condition     = length(var.s3_bucket_name) >= 3 && length(var.s3_bucket_name) <= 63
    error_message = "S3 bucket name must be 3-63 characters."
  }
}

variable "versioning_enabled" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable S3 encryption"
  type        = bool
  default     = true
}

variable "enable_lifecycle_rules" {
  description = "Enable S3 lifecycle rules"
  type        = bool
  default     = true
}
