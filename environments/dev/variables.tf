/**
 * Development Environment - Variables
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

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# VPC Variables
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "dev-key" # Change to your key pair name
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Restrict in production
}

# RDS Variables
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
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
}

variable "allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "admin"
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
  default     = "appdb"
}

variable "backup_retention_period" {
  description = "RDS backup retention days"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

# S3 Variables
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "3-tier-app-bucket-dev" # Change to a globally unique name

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
