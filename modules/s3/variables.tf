/**
 * S3 Module - Variables
 */

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9-]*$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase letters, numbers, and hyphens only."
  }
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

variable "versioning_enabled" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable encryption on the bucket"
  type        = bool
  default     = true
}

variable "encryption_algorithm" {
  description = "Encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (required if encryption_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

variable "enable_lifecycle_rules" {
  description = "Enable lifecycle rules"
  type        = bool
  default     = true
}

variable "transition_days" {
  description = "Days before transitioning to GLACIER"
  type        = number
  default     = 90

  validation {
    condition     = var.transition_days >= 30
    error_message = "Transition days must be at least 30."
  }
}

variable "expiration_days" {
  description = "Days before expiring objects"
  type        = number
  default     = 365

  validation {
    condition     = var.expiration_days >= var.transition_days
    error_message = "Expiration days must be >= transition days."
  }
}

variable "enable_logging" {
  description = "Enable bucket logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "Bucket for access logs"
  type        = string
  default     = null
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete (requires versioning)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
