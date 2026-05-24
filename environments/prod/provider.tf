/**
 * Production Environment - Provider Configuration
 */

terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configure remote state for production
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      CreatedAt   = timestamp()
    }
  }
}

# Data source to get current AWS account information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
