/**
 * Development Environment - Outputs
 */

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_eip" {
  description = "NAT Gateway Elastic IP"
  value       = module.vpc.nat_gateway_eip
}

# EC2 Outputs
output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 Public IP"
  value       = module.ec2.public_ip
}

output "ec2_private_ip" {
  description = "EC2 Private IP"
  value       = module.ec2.private_ip
}

output "ec2_ssh_command" {
  description = "SSH command to connect to EC2"
  value       = module.ec2.ssh_command
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS Database Endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_address" {
  description = "RDS Database Address"
  value       = module.rds.db_instance_address
}

output "rds_port" {
  description = "RDS Database Port"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "RDS Database Name"
  value       = module.rds.db_name
}

output "rds_username" {
  description = "RDS Database Username"
  value       = module.rds.db_username
  sensitive   = true
}

# S3 Outputs
output "s3_bucket_id" {
  description = "S3 Bucket ID"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = module.s3.bucket_arn
}

output "s3_bucket_domain_name" {
  description = "S3 Bucket Domain Name"
  value       = module.s3.bucket_domain_name
}

# Security Groups
output "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  value       = module.security_groups.ec2_security_group_id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = module.security_groups.rds_security_group_id
}

# IAM Outputs
output "ec2_iam_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = module.iam.ec2_role_arn
}

output "instance_profile_name" {
  description = "EC2 Instance Profile Name"
  value       = module.iam.instance_profile_name
}

# Summary Output
output "deployment_summary" {
  description = "Deployment Summary"
  value = {
    region       = var.aws_region
    environment  = var.environment
    project_name = var.project_name
    vpc_id       = module.vpc.vpc_id
    ec2_instance = module.ec2.instance_id
    rds_database = module.rds.db_instance_identifier
    s3_bucket    = module.s3.bucket_id
  }
}
