/**
 * S3 Module - Main Configuration
 * Creates S3 bucket with encryption, versioning, and security best practices
 */

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "Terraform"
      Module      = "S3"
    }
  )
}

# Create S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = var.bucket_name
    }
  )

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.enable_mfa_delete && var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.encryption_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm      = var.encryption_algorithm
      kms_master_key_id  = var.encryption_algorithm == "aws:kms" ? var.kms_key_id : null
    }
    bucket_key_enabled = true
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# ACL
resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# Bucket Logging
resource "aws_s3_bucket_logging" "main" {
  count  = var.enable_logging && var.logging_bucket != null ? 1 : 0
  bucket = aws_s3_bucket.main.id

  target_bucket = var.logging_bucket
  target_prefix = "logs/"
}

# Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "TransitionOldVersions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Transition to GLACIER
    noncurrent_version_transition {
      noncurrent_days = var.transition_days
      storage_class   = "GLACIER"
    }

    # Expire very old versions
    noncurrent_version_expiration {
      noncurrent_days = var.expiration_days
    }
  }

  # Optional: Transition current versions
  rule {
    id     = "TransitionCurrentVersions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }

  rule {
    id     = "DeleteIncompleteMultipartUploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

# Bucket Policy (to be defined at environment level)
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = [var.encryption_algorithm]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Apply Bucket Policy
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# CORS Configuration (optional)
resource "aws_s3_bucket_cors_configuration" "main" {
  count  = 0 # Set to 1 if CORS is needed
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Request Metrics (optional)
resource "aws_s3_bucket_metric" "entire_bucket" {
  bucket = aws_s3_bucket.main.id
  name   = "EntireBucket"
}
