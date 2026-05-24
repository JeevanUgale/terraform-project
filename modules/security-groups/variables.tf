/**
 * Security Groups Module - Variables
 */

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

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

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to EC2 instances"
  type        = string
  default     = "0.0.0.0/0" # WARNING: In production, restrict this to specific IPs

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "Allowed SSH CIDR must be a valid IPv4 CIDR block."
  }
}

variable "enable_http" {
  description = "Enable HTTP access to EC2"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable HTTPS access to EC2"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
