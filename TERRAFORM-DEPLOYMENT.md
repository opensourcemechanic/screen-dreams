# AWS Terraform Deployment Guide

## Quick Start Guide

### Prerequisites
- AWS account with Free Tier
- Terraform installed
- AWS CLI configured
- SSH key pair

### Step 1: Setup
```bash
# Clone repository
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams/terraform

# Configure AWS credentials
aws configure

# Copy variables template
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Configure Variables
Edit `terraform.tfvars` with your values:

```hcl
# Required
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
ai_provider = "openai"
openai_api_key = "sk-your-openai-api-key-here"

# Optional (will be auto-generated)
# db_password = "your-secure-password"
# secret_key = "your-256-character-secret-key"
```

### Step 3: Deploy
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply

# Confirm when prompted
```

### Step 4: Access Application
```bash
# Get public IP
terraform output public_ip

# Access application
curl http://<public-ip>

# SSH to instance
terraform output ssh_command
```

## Configuration Options

### AI Providers
- **OpenAI**: Set `ai_provider = "openai"` and `openai_api_key`
- **Anthropic**: Set `ai_provider = "anthropic"` and `anthropic_api_key`
- **IONOS**: Set `ai_provider = "ionos"` and `ionos_api_key`
- **Scaleway**: Set `ai_provider = "scaleway"` and `scaleway_api_key`

### Instance Types
- **Free Tier**: `instance_type = "t3.micro"` (default)
- **After Free Tier**: `instance_type = "t4g.nano"` (cheaper)

### Security
- **SSH Access**: Set `allowed_ssh_cidr` to your IP only
- **Database**: Password auto-generated, or set `db_password`

## Management Commands

### Check Status
```bash
# SSH to instance
ssh -i key.pem ec2-user@<public-ip>

# Run health check
./health-check.sh

# View application logs
cd /opt/screen-dreams
docker-compose logs -f screen-dreams
```

### Update Application
```bash
# SSH to instance
ssh -i key.pem ec2-user@<public-ip>

# Update to latest version
./update-app.sh
```

### Database Access
```bash
# SSH to instance
ssh -i key.pem ec2-user@<public-ip>

# Access database
cd /opt/screen-dreams
docker-compose exec postgres psql -U screenwriter -d screenwriter_db
```

## Cost Monitoring

### Free Tier Usage
- **EC2**: 750 hours/month free
- **RDS**: 750 hours/month free
- **S3**: 5GB free
- **Data Transfer**: 100GB free

### Billing Alert
Automatic alert configured at $10/month threshold.

### Check Costs
```bash
# AWS Console > Billing > Cost Explorer
# Or use AWS CLI
aws ce get-cost-and-usage --time-period Start=<start>,End=<end>
```

## Troubleshooting

### Common Issues

#### Instance Not Accessible
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check instance state
aws ec2 describe-instances --instance-ids <instance-id>
```

#### Application Not Starting
```bash
# SSH to instance
ssh -i key.pem ec2-user@<public-ip>

# Check Docker logs
cd /opt/screen-dreams
docker-compose logs screen-dreams

# Check environment
cat /opt/screen-dreams/.env
```

#### Database Connection Issues
```bash
# Test database connection
ssh -i key.pem ec2-user@<public-ip>
docker-compose exec postgres pg_isready -U screenwriter -d screenwriter_db
```

#### High Costs
```bash
# Check billing
aws ce get-cost-and-usage --time-period Start=2023-01-01,End=2023-01-31

# Check resource usage
aws ec2 describe-instances
aws rds describe-db-instances
aws s3 ls
```

## Upgrade Paths

### Add Redis Cache (After Free Tier)
```bash
# Modify terraform files
# Add ElastiCache resources
# Cost: +$8/month
```

### Add SSL Certificate
```bash
# Add domain name variable
# Enable HTTPS in configuration
# Cost: Domain registration only
```

### Add Load Balancer
```bash
# Add ALB resources
# Configure target groups
# Cost: +$25/month
```

## Cleanup

### Destroy Resources
```bash
# Remove all infrastructure
terraform destroy

# Confirm when prompted
```

### Partial Cleanup
```bash
# Stop instance (keep data)
aws ec2 stop-instances --instance-ids <instance-id>

# Delete specific resources
terraform destroy -target=aws_instance.screen_dreams
```

## Security Best Practices

1. **Restrict SSH Access**: Use your IP only in `allowed_ssh_cidr`
2. **Use Strong Credentials**: Let Terraform generate passwords
3. **Regular Updates**: Use update script frequently
4. **Monitor Costs**: Check billing dashboard regularly
5. **Backup Data**: Database backups enabled automatically
6. **Rotate Keys**: Change SSH keys periodically

## Support Resources

- **Terraform Documentation**: https://www.terraform.io/docs
- **AWS Free Tier**: https://aws.amazon.com/free/
- **Screen Dreams Issues**: https://github.com/opensourcemechanic/screen-dreams/issues
- **AWS Support**: Included with Free Tier account

## Next Steps

1. **Deploy** your instance using this guide
2. **Configure** your AI provider and test functionality
3. **Monitor** costs and resource usage
4. **Plan** upgrades when approaching Free Tier limits
5. **Scale** using upgrade paths when ready

This deployment provides a complete Screen Dreams instance using only AWS Free Tier resources for 12 months.
