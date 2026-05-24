/**
 * Backend Configuration for Remote State Management
 * 
 * This file contains the configuration for storing Terraform state remotely
 * in AWS S3 with DynamoDB for state locking.
 * 
 * Implementation Steps:
 * 1. Create S3 bucket and DynamoDB table manually or with separate Terraform
 * 2. Update the backend block in versions.tf with your values
 * 3. Run: terraform init -migrate-state
 */

# Example S3 Backend Configuration
# Copy this to versions.tf backend block after creating the S3 bucket and DynamoDB table

/*
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "3-tier-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
*/

# Optional: Create S3 bucket and DynamoDB table for backend (run this in a separate directory first)
/*
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "shared"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = "shared"
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}
*/
