#!/bin/bash
# EC2 User Data Script
# Runs during instance initialization

set -e

# Update system
yum update -y

# Install essential tools
yum install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    telnet \
    aws-cli \
    jq

# Configure CloudWatch agent (optional)
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
# rpm -U ./amazon-cloudwatch-agent.rpm

# Create application directory
mkdir -p /opt/app
chown -R ec2-user:ec2-user /opt/app

# Log user data execution
echo "User data script executed successfully" > /var/log/user-data.log

# Set environment variables for S3 access
cat >> /home/ec2-user/.bashrc << 'EOF'
# AWS CLI configuration
export AWS_DEFAULT_REGION=$(ec2-metadata --availability-zone | cut -d ' ' -f 2 | sed 's/[a-z]$//')
export AWS_ACCOUNT_ID=$(ec2-metadata --iam-security-credentials | cut -d ' ' -f 2)
EOF

echo "EC2 initialization complete"
