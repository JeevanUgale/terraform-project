#!/bin/bash
# User data script for EC2 - Production Environment
# This script runs when the instance starts

set -e

# Log file
LOG_FILE="/var/log/user-data.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting EC2 user data script (Production)..."

# Update system packages securely
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
    postgresql \
    docker \
    ntp

# Start NTP for time synchronization (important for security)
log_message "Enabling NTP service..."
systemctl start ntpd
systemctl enable ntpd

# Start Docker daemon
log_message "Starting Docker daemon..."
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Configure SSH hardening
log_message "Configuring SSH security..."
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Create application directory
log_message "Creating application directory..."
mkdir -p /opt/app
chown -R ec2-user:ec2-user /opt/app
chmod 755 /opt/app

# Set environment variables for production
log_message "Setting environment variables..."
cat >> /home/ec2-user/.bashrc << 'ENVSCRIPT'
# AWS Configuration
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")

# Application Configuration
export S3_BUCKET="${s3_bucket}"
export DB_HOST="${db_host}"
export DB_NAME="${db_name}"
export DB_USER="postgres"
export DB_PORT="5432"

# Application settings
export APP_ENV="production"
export LOG_LEVEL="INFO"
export ENABLE_MONITORING="true"
export ENABLE_LOGGING="true"

ENVSCRIPT

chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Install CloudWatch agent for monitoring
log_message "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm amazon-cloudwatch-agent.rpm

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/application",
            "log_stream_name": "application-logs"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/system",
            "log_stream_name": "system-logs"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CustomMetrics",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_iowait",
            "rename": "CPU_IOWAIT",
            "unit": "Percent"
          }
        ]
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ]
      }
    }
  }
}
CWCONFIG

# Start CloudWatch agent
log_message "Starting CloudWatch agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Test S3 access
log_message "Testing S3 access..."
if su - ec2-user -c "aws s3 ls s3://${s3_bucket} 2>&1" >> "$LOG_FILE"; then
    log_message "S3 access confirmed"
else
    log_message "Warning: S3 access check failed"
fi

# Test RDS connectivity
log_message "Testing RDS connectivity..."
if command -v psql &> /dev/null; then
    if PGPASSWORD="$DB_PASSWORD" psql -h ${db_host} -U postgres -d ${db_name} -c "SELECT version();" 2>&1 >> "$LOG_FILE"; then
        log_message "RDS connectivity confirmed"
    else
        log_message "Note: RDS connectivity test skipped (credentials may not be available)"
    fi
fi

# Create application startup script
cat > /opt/app/start.sh << 'APPSCRIPT'
#!/bin/bash
echo "Production Application Starting..."
echo "Timestamp: $(date)"
echo "Environment: $APP_ENV"
echo "S3 Bucket: $S3_BUCKET"
echo "Database: $DB_NAME on $DB_HOST"
echo "AWS Region: $AWS_DEFAULT_REGION"
APPSCRIPT

chmod +x /opt/app/start.sh
chown ec2-user:ec2-user /opt/app/start.sh

# Create health check script
cat > /opt/app/health_check.sh << 'HEALTHSCRIPT'
#!/bin/bash
# Health check for monitoring

STATUS="HEALTHY"

# Check if S3 is accessible
if ! aws s3 ls s3://${S3_BUCKET} &>/dev/null; then
    STATUS="UNHEALTHY"
    echo "S3 access check failed"
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    STATUS="UNHEALTHY"
    echo "Disk usage critical: $DISK_USAGE%"
fi

# Check memory
MEM_USAGE=$(free | awk 'NR==2 {print int($3/$2*100)}')
if [ "$MEM_USAGE" -gt 85 ]; then
    STATUS="UNHEALTHY"
    echo "Memory usage critical: $MEM_USAGE%"
fi

echo $STATUS
HEALTHSCRIPT

chmod +x /opt/app/health_check.sh
chown ec2-user:ec2-user /opt/app/health_check.sh

log_message "EC2 user data script completed successfully"
log_message "Production environment initialization complete"
