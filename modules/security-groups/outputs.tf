/**
 * Security Groups Module - Outputs
 */

output "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "ec2_security_group_name" {
  description = "EC2 Security Group Name"
  value       = aws_security_group.ec2.name
}

output "rds_security_group_name" {
  description = "RDS Security Group Name"
  value       = aws_security_group.rds.name
}
