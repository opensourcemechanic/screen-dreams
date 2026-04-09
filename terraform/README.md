# Screen Dreams AWS Free Tier Deployment

This Terraform configuration deploys Screen Dreams to AWS using only Free Tier eligible resources, costing $0/month for the first 12 months.

## Architecture

- **EC2 t3.micro**: Application server (Free Tier)
- **RDS db.t3.micro**: PostgreSQL database (Free Tier)
- **S3**: 5GB file storage (Free Tier)
- **VPC**: Basic networking (Always Free)

## Prerequisites

1. **AWS Account** with Free Tier
2. **Terraform** installed locally
3. **AWS CLI** installed and configured
4. **SSH Key Pair** for instance access

## Quick Start

### 1. Setup AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region (us-east-1), and output format (json)
```

### 2. Clone and Setup
```bash
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams/terraform
```

### 3. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
nano terraform.tfvars
```

**Required variables to configure:**
- `ssh_public_key`: Your SSH public key
- `ai_provider`: Your preferred AI provider
- `openai_api_key`: Your OpenAI API key (if using OpenAI)

### 4. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 5. Access Application
```bash
# Get the public IP
terraform output public_ip

# Access the application
curl http://<public-ip>

# SSH to the instance
terraform output ssh_command
```

## Configuration

### Instance Types
- **Free Tier**: `t3.micro` (2 vCPU, 1GB RAM)
- **After Free Tier**: `t4g.nano` (1 vCPU, 512MB RAM) - cheaper option

### AI Providers
Supported AI providers (bring your own API key):
- **OpenAI**: GPT models (~$0.002/1K tokens)
- **Anthropic**: Claude models (~$0.003/1K tokens)
- **IONOS**: European Llama models (~$0.0007/1K tokens)
- **Scaleway**: European Llama models (~$0.0009/1K tokens)

### Security
- SSH key-based authentication
- Restrictive security groups
- Encrypted storage
- No secrets in code (use environment variables)

## Cost Analysis

### Free Tier (Months 1-12)
- **EC2 t3.micro**: $0 (750 hours free)
- **RDS db.t3.micro**: $0 (750 hours free)
- **S3 5GB**: $0 (5GB free)
- **Data Transfer**: $0 (100GB free)
- **Total**: $0/month

### After Free Tier (Months 13+)
- **EC2 t3.micro**: ~$12/month
- **RDS db.t3.micro**: ~$15/month
- **S3**: ~$3/month
- **Data Transfer**: ~$5/month
- **Total**: ~$35/month

## Management

### Check Application Status
```bash
ssh -i key.pem ec2-user@<public-ip>
./health-check.sh
```

### Update Application
```bash
ssh -i key.pem ec2-user@<public-ip>
./update-app.sh
```

### View Logs
```bash
ssh -i key.pem ec2-user@<public-ip>
cd /opt/screen-dreams
docker-compose logs -f screen-dreams
```

### Database Access
```bash
ssh -i key.pem ec2-user@<public-ip>
cd /opt/screen-dreams
docker-compose exec postgres psql -U screenwriter -d screenwriter_db
```

## Monitoring

### Cost Alerts
Automatic billing alert configured to notify if charges exceed $10/month.

### CloudWatch Metrics
Basic monitoring included (free tier):
- EC2 instance metrics
- Database performance
- S3 storage usage

## Security Best Practices

1. **Restrict SSH Access**: Set `allowed_ssh_cidr` to your IP only
2. **Use Strong Passwords**: Let Terraform generate random passwords
3. **Regular Updates**: Use the update script to keep application current
4. **Monitor Costs**: Check AWS billing regularly
5. **Backup Data**: Database backups enabled automatically

## Troubleshooting

### Instance Not Accessible
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check instance status
aws ec2 describe-instances --instance-ids <instance-id>
```

### Application Not Starting
```bash
# Check Docker logs
ssh -i key.pem ec2-user@<public-ip>
docker-compose logs screen-dreams

# Check environment variables
cat /opt/screen-dreams/.env
```

### Database Connection Issues
```bash
# Test database connection
ssh -i key.pem ec2-user@<public-ip>
docker-compose exec postgres pg_isready -U screenwriter -d screenwriter_db
```

## Upgrade Paths

When ready to scale beyond free tier:

### Add Redis Cache
```hcl
# In terraform files
enable_redis = true
# Cost: +$8/month
```

### Add Load Balancer
```hcl
# In terraform files
enable_load_balancer = true
# Cost: +$25/month
```

### Add SSL Certificate
```hcl
# In terraform files
enable_https = true
domain_name = "yourdomain.com"
# Cost: $0 + domain registration
```

## Cleanup

To destroy all resources and avoid charges:
```bash
terraform destroy
```

## Support

- **Documentation**: [Screen Dreams README](../README.md)
- **Issues**: [GitHub Issues](https://github.com/opensourcemechanic/screen-dreams/issues)
- **AWS Support**: Free tier includes basic support

## Next Steps

1. **Deploy** using this configuration
2. **Test** all application features
3. **Configure** your preferred AI provider
4. **Monitor** costs and usage
5. **Plan** upgrades when ready to scale

This deployment provides a complete, production-ready Screen Dreams instance using only AWS Free Tier resources for 12 months.
