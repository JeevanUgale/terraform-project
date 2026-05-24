/**
 * Security Groups Module - Main Configuration
 * Creates security groups for EC2 and RDS with least privilege rules
 */

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "Terraform"
      Module      = "Security-Groups"
    }
  )
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg-${var.environment}"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-ec2-sg-${var.environment}"
    }
  )
}

# EC2 Security Group - Ingress Rules
# SSH Access
resource "aws_security_group_rule" "ec2_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_cidr]
  security_group_id = aws_security_group.ec2.id
  description       = "Allow SSH from specified CIDR"
}

# HTTP Access (optional)
resource "aws_security_group_rule" "ec2_http" {
  count             = var.enable_http ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
  description       = "Allow HTTP"
}

# HTTPS Access (optional)
resource "aws_security_group_rule" "ec2_https" {
  count             = var.enable_https ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
  description       = "Allow HTTPS"
}

# EC2 Security Group - Egress Rule (allow all outbound)
resource "aws_security_group_rule" "ec2_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound traffic"
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-rds-sg-${var.environment}"
    }
  )
}

# RDS Security Group - Ingress Rule (only from EC2)
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow MySQL access from EC2 security group"
}

# RDS Security Group - Egress Rule (allow all outbound)
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}
