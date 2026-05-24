/**
 * EC2 Module - Main Configuration
 * Creates EC2 instance with IAM role for S3 access
 */

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "Terraform"
      Module      = "EC2"
    }
  )
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create EC2 Instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile

  # Root volume configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project_name}-ec2-root-volume-${var.environment}"
      }
    )
  }

  # Enable detailed monitoring
  monitoring = var.enable_monitoring

  # User data script
  user_data = base64encode(var.user_data != "" ? var.user_data : file("${path.module}/user_data.sh"))

  # Metadata options for improved security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 enforced
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # CPU options
  cpu_options {
    core_count       = 1
    threads_per_core = 1
  }

  # Disable detailed Nitro encryption (if supported by instance type)
  # This ensures EBS volumes are encrypted

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-ec2-${var.environment}"
    }
  )

  depends_on = []
}

# Elastic IP for EC2 (optional, for static IP)
resource "aws_eip" "ec2" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-ec2-eip-${var.environment}"
    }
  )

  depends_on = [aws_instance.main]
}
