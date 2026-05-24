#!/bin/bash
# User data script for EC2 - Development Environment
# This script runs when the instance starts

set -e

# Log file
LOG_FILE="/var/log/user-data.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting EC2 user data script..."

# Update system packages
log_message "Updating system packages..."
yum update -y

# Install essential tools
log_message "Installing essential tools..."
yum install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    telnet \
    aws-cli \
    jq \
    mysql \
    docker

# Start Docker daemon
log_message "Starting Docker daemon..."
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Create application directory
log_message "Creating application directory..."
mkdir -p /opt/app
chown -R ec2-user:ec2-user /opt/app

# Set environment variables
log_message "Setting environment variables..."
cat >> /home/ec2-user/.bashrc << 'ENVSCRIPT'
# AWS Configuration
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")

# Application Configuration
export S3_BUCKET="${s3_bucket}"
export DB_HOST="${db_host}"
export DB_NAME="${db_name}"
export DB_USER="admin"
export DB_PORT="3306"

# Application settings
export APP_ENV="development"
export LOG_LEVEL="DEBUG"

ENVSCRIPT

chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Test S3 access
log_message "Testing S3 access..."
if su - ec2-user -c "aws s3 ls s3://${s3_bucket} 2>&1" >> "$LOG_FILE"; then
    log_message "S3 access confirmed"
else
    log_message "Warning: S3 access check failed"
fi

# Test RDS connectivity
log_message "Testing RDS connectivity..."
if command -v mysql &> /dev/null; then
    if mysql -h ${db_host} -u admin -p"$DB_PASSWORD" ${db_name} -e "SELECT 1" 2>&1 >> "$LOG_FILE"; then
        log_message "RDS connectivity confirmed"
    else
        log_message "Warning: RDS connectivity test failed (password may not be set yet)"
    fi
fi

# Create a sample application startup script
cat > /opt/app/start.sh << 'APPSCRIPT'
#!/bin/bash
echo "Application starting..."
echo "S3 Bucket: $S3_BUCKET"
echo "Database: $DB_NAME on $DB_HOST"
APPSCRIPT

chmod +x /opt/app/start.sh
chown ec2-user:ec2-user /opt/app/start.sh

log_message "EC2 user data script completed successfully"
