/**
 * EC2 Module - Variables
 */

variable "ami" {
  description = "AMI ID for EC2 instance (Amazon Linux 2)"
  type        = string
  default     = "ami-0c94855ba95c574c8" # Amazon Linux 2 - us-east-1, change per region

  # Note: Use data source in actual deployment to get latest AMI
  # data "aws_ami" "amazon_linux_2" {
  #   most_recent = true
  #   owners      = ["amazon"]
  #   filter {
  #     name   = "name"
  #     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  #   }
  # }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "m5.large", "m5.xlarge"], var.instance_type)
    error_message = "Instance type must be from the approved list."
  }
}

variable "subnet_id" {
  description = "Subnet ID where EC2 instance will be launched (public subnet)"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID for EC2 instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile name"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string

  validation {
    condition     = length(var.key_name) > 0
    error_message = "Key name must be provided."
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

variable "user_data" {
  description = "User data script for EC2 initialization"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 20
    error_message = "Root volume size must be at least 20 GB."
  }
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
