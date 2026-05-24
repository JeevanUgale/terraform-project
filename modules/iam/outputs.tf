/**
 * IAM Module - Outputs
 */

output "ec2_role_id" {
  description = "EC2 IAM Role ID"
  value       = aws_iam_role.ec2_role.id
}

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "instance_profile_arn" {
  description = "EC2 Instance Profile ARN"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "instance_profile_name" {
  description = "EC2 Instance Profile Name"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "s3_policy_arn" {
  description = "S3 Access Policy ARN"
  value       = aws_iam_policy.ec2_s3_policy.arn
}

output "cloudwatch_policy_arn" {
  description = "CloudWatch Logs Policy ARN"
  value       = aws_iam_policy.ec2_cloudwatch_policy.arn
}
