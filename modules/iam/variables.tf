/**
 * IAM Module - Variables
 */

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "owner" {
  description = "Owner of the project"
  type        = string
  default     = "DevOps Team"
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for EC2 access"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
