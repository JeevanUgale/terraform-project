# Quick Start Guide

## 5-Minute Setup

### Prerequisites

```bash
# Verify installations
terraform version          # >= 1.3
aws --version             # >= 2.0
aws sts get-caller-identity  # Verify credentials
```

### Step 1: Navigate to Dev Environment (1 min)

```bash
cd environments/dev
```

### Step 2: Update Configuration (1 min)

```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Change these values:
# 1. key_name = "your-ec2-key-pair"
# 2. s3_bucket_name = "unique-bucket-name-12345"
# 3. db_password = "YourSecurePassword123!"
```

### Step 3: Initialize Terraform (1 min)

```bash
terraform init
```

### Step 4: Review Plan (1 min)

```bash
terraform plan
```

### Step 5: Deploy Infrastructure (1 min)

```bash
terraform apply -auto-approve
```

### Done! Get Your Outputs

```bash
terraform output
```

---

## Common Commands Cheat Sheet

### Planning & Deployment

```bash
# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Force apply (dev only)
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy -auto-approve
```

### Inspection

```bash
# Show all outputs
terraform output

# Show specific output
terraform output ec2_public_ip

# View state
terraform show

# List resources
terraform state list

# Show resource details
terraform state show module.ec2.aws_instance.main
```

### Management

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Refresh state
terraform refresh

# Force resource recreation
terraform taint module.ec2.aws_instance.main
terraform apply
```

---

## Troubleshooting Quick Reference

| Issue                 | Solution                                                            |
| --------------------- | ------------------------------------------------------------------- |
| "InvalidKeyPair"      | Create EC2 key pair:`aws ec2 create-key-pair --key-name dev-key`  |
| "BucketAlreadyExists" | Change `s3_bucket_name` to unique name                            |
| "InvalidCredential"   | Run `aws configure` to set credentials                            |
| "Permission denied"   | EC2 key pair permissions:`chmod 400 dev-key.pem`                  |
| "Subnet not found"    | VPC might not have created yet; check security groups depend on VPC |

---

## Next Steps After Deployment

### 1. Connect to EC2

```bash
# Get public IP
EC2_IP=$(terraform output -raw ec2_public_ip)

# SSH into instance
ssh -i dev-key.pem ec2-user@$EC2_IP
```

### 2. Test RDS Connection

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_address)

# Connect (requires mysql client)
mysql -h $RDS_ENDPOINT -u admin -p
```

### 3. Test S3 Access

```bash
# Get bucket name
BUCKET=$(terraform output -raw s3_bucket_id)

# Upload test file
echo "test" > test.txt
aws s3 cp test.txt s3://$BUCKET/
```

### 4. Verify Security Groups

```bash
# Check EC2 security group
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw ec2_security_group_id)
```

---

## Scaling Guide

### Increase Instance Size (Dev → Prod)

```bash
# Edit terraform.tfvars
instance_type = "t3.small"  # Changed from t3.micro

# Apply changes
terraform plan
terraform apply
```

### Add More Database Storage

```bash
# Edit terraform.tfvars
allocated_storage = 100  # Changed from 20

# Modify DB instance
aws rds modify-db-instance \
  --db-instance-identifier 3-tier-app-db-dev \
  --allocated-storage 100 \
  --apply-immediately
```

---

## Cost Tracking

### Check Current Spending

```bash
# Last 24 hours
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 day ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Estimate Monthly Cost (Dev)

- EC2: ~$7/month (t3.micro)
- RDS: ~$24/month (db.t3.micro)
- NAT Gateway: ~$32/month
- Data transfer: ~$5-10/month
- **Total: ~$70-80/month**

---

## Production Deployment

### Switch to Production

```bash
cd ../prod

# Update terraform.tfvars
nano terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply
```

## Cleanup

### Destroy All Resources

```bash
terraform destroy -auto-approve
```

### Destroy Specific Resource

```bash
terraform destroy -target=module.ec2.aws_instance.main
```

### Clean Local State

```bash
rm -rf .terraform
rm terraform.tfstate*
```

---

## Example Workflows

### Complete Deployment Workflow

```bash
# 1. Setup
cd environments/dev
terraform init

# 2. Configure
echo "Update terraform.tfvars"
nano terraform.tfvars

# 3. Plan
terraform plan -out=tfplan

# 4. Review (check output)
terraform show tfplan

# 5. Apply
terraform apply tfplan

# 6. Verify
terraform output

# 7. Test
EC2_IP=$(terraform output -raw ec2_public_ip)
ssh -i dev-key.pem ec2-user@$EC2_IP
```

### Update and Rollback

```bash
# 1. Make changes
nano terraform.tfvars

# 2. Plan
terraform plan -out=tfplan

# 3. Review changes
terraform show tfplan

# 4. Rollback if needed
# Edit back to previous state
nano terraform.tfvars

# 5. Or destroy and reapply
terraform destroy -auto-approve
terraform apply -auto-approve
```

---

## Getting Help

### Documentation

- `terraform help` - Terraform help
- `terraform <command> --help` - Command help
- [Terraform Docs](https://www.terraform.io/docs)
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws)

### Debug Output

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log
terraform apply
tail -f /tmp/terraform.log
```

## Support Resources

| Topic            | Resource                                                                             |
| ---------------- | ------------------------------------------------------------------------------------ |
| Terraform Errors | [Terraform Discord](https://discord.gg/terraform)                                       |
| AWS Questions    | [AWS Forums](https://forums.aws.amazon.com/)                                            |
| Security Issues  | [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)          |
| Performance      | [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) |
