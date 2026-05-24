/**
 * IAM Module - Main Configuration
 * Creates IAM role, policies, and instance profile for EC2 to access S3
 */

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "Terraform"
      Module      = "IAM"
    }
  )
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-ec2-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-ec2-role-${var.environment}"
    }
  )
}

# Trust relationship for EC2 service
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy for S3 Access (least privilege)
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "${var.project_name}-ec2-s3-policy-${var.environment}"
  description = "Policy for EC2 to access S3 bucket"
  policy      = data.aws_iam_policy_document.ec2_s3_policy.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "ec2_s3_policy" {
  # List bucket permissions
  statement {
    sid    = "ListBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning"
    ]

    resources = [var.s3_bucket_arn]
  }

  # Object permissions (read and write)
  statement {
    sid    = "GetPutDeleteObject"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion"
    ]

    resources = ["${var.s3_bucket_arn}/*"]
  }

  # Encryption related
  statement {
    sid    = "EncryptionPermissions"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}

# Optional: Add policy for CloudWatch Logs (for monitoring)
resource "aws_iam_policy" "ec2_cloudwatch_policy" {
  name        = "${var.project_name}-ec2-cloudwatch-policy-${var.environment}"
  description = "Policy for EC2 to write logs to CloudWatch"
  policy      = data.aws_iam_policy_document.ec2_cloudwatch_policy.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "ec2_cloudwatch_policy" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/*"]
  }

  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData"
    ]

    resources = ["*"]
  }
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_cloudwatch_policy.arn
}

# SSM access for AWS Systems Manager (optional but recommended)
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Data source for current account and region
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
