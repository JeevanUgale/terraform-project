/**
 * EC2 Module - Outputs
 */

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "EC2 Instance ARN"
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.ec2.public_ip
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.main.ami
}

output "subnet_id" {
  description = "Subnet ID where instance is launched"
  value       = aws_instance.main.subnet_id
}

output "vpc_security_group_ids" {
  description = "Security group IDs attached to the instance"
  value       = aws_instance.main.vpc_security_group_ids
}

output "iam_instance_profile" {
  description = "IAM Instance Profile"
  value       = aws_instance.main.iam_instance_profile
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.main.availability_zone
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /path/to/key.pem ec2-user@${aws_eip.ec2.public_ip}"
}
