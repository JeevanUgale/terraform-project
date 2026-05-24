/**
 * S3 Module - Outputs
 */

output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.main.region
}

output "versioning_enabled" {
  description = "Versioning status"
  value       = aws_s3_bucket_versioning.main.versioning_configuration[0].status
}

output "encryption_algorithm" {
  description = "Encryption algorithm"
  value       = var.encryption_algorithm
}

output "public_access_blocked" {
  description = "Public access blocked status"
  value       = aws_s3_bucket_public_access_block.main.block_public_acls
}
