# IONOS Cloud Terraform Deployment Example

This is an example of how to deploy Screen Dreams to IONOS Cloud using Terraform. Use this as reference for future migration from AWS.

## Architecture Overview

### IONOS Cloud Components
- **Datacenter**: Similar to AWS VPC
- **Server**: Virtual machine (similar to EC2)
- **PostgreSQL Database**: Managed database service
- **S3 Bucket**: Object storage (similar to AWS S3)
- **Firewall Rules**: Security groups (similar to AWS SG)
- **IP Block**: Static IP address

## Cost Comparison

### IONOS vs AWS
- **IONOS**: No free tier, but lower ongoing costs
- **AWS**: 12 months free tier, then higher costs
- **IONOS AI**: European LLMs at 10-15% of US costs
- **GDPR**: Built-in compliance with European regulations

### Estimated Monthly Costs (IONOS)
- **Server**: ~$15-25/month (2 cores, 4GB RAM)
- **Database**: ~$20-30/month (PostgreSQL)
- **Storage**: ~$5-10/month (S3)
- **IP Block**: ~$2/month
- **Total**: ~$42-67/month

## Prerequisites

1. **IONOS Cloud Account**: https://cloud.ionos.com/
2. **Terraform**: Installed locally
3. **IONOS Credentials**: Username and password

## Quick Start

### 1. Setup Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your IONOS credentials
nano terraform.tfvars
```

### 2. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 3. Access Application
```bash
# Get public IP
terraform output server_public_ip

# Access application
curl http://<public-ip>

# SSH to server
terraform output ssh_command
```

## Key Differences from AWS

### Resource Mapping
| AWS | IONOS | Description |
|-----|-------|-------------|
| VPC | Datacenter | Network isolation |
| EC2 | Server | Virtual machine |
| RDS | Database | Managed database |
| S3 | S3 Bucket | Object storage |
| Security Group | Firewall | Network security |
| EIP | IP Block | Static IP |

### Configuration Differences
- **No Free Tier**: IONOS doesn't offer a free tier
- **European Regions**: Frankfurt, Berlin, etc.
- **GDPR Compliance**: Built-in European data protection
- **AI Integration**: Direct access to European LLMs

## Migration Considerations

### When to Migrate from AWS to IONOS
1. **After Free Tier**: When AWS costs start
2. **GDPR Requirements**: Need European data residency
3. **Cost Optimization**: IONOS AI services are cheaper
4. **European Market**: Better performance for European users

### Migration Steps
1. **Backup Data**: Export from AWS RDS and S3
2. **Deploy IONOS**: Use this Terraform configuration
3. **Import Data**: Restore database and files
4. **Update DNS**: Point domain to new IP
5. **Decommission AWS**: Remove AWS resources

## AI Provider Advantages

### IONOS AI Model Hub
- **European LLMs**: Llama 3.3 70B, Mistral, etc.
- **Cost Effective**: ~$0.0007/1K tokens (vs $0.002 for OpenAI)
- **GDPR Compliant**: Data stays in Europe
- **No Infrastructure**: No need to manage AI servers

### Configuration
```hcl
# Use IONOS AI (recommended)
ai_provider = "ionos"
ionos_api_key = "your-ionos-ai-key"

# Or use other providers
ai_provider = "openai"
openai_api_key = "sk-your-key"
```

## Troubleshooting

### Common Issues
- **Authentication**: Check IONOS credentials
- **Regions**: Ensure correct region format (de/fra)
- **Quotas**: Check IONOS resource limits
- **Networking**: Verify firewall rules

### Debug Commands
```bash
# Check server status
ionoscloud server get --datacenter-id <dc-id> --server-id <server-id>

# Check database status
ionoscloud dbaas-postgres get --cluster-id <cluster-id>

# Check firewall rules
ionoscloud firewallrule list --datacenter-id <dc-id> --server-id <server-id>
```

## Advantages

### IONOS Benefits
- **European Data Residency**: GDPR compliant
- **Cost Effective**: Lower ongoing costs
- **European AI**: Access to European LLMs
- **Support**: European time zones, German/English

### Considerations
- **No Free Tier**: Costs start immediately
- **Smaller Community**: Fewer examples/documentation
- **Provider Maturity**: Less mature than AWS
- **Region Coverage**: Limited to European regions

## Next Steps

1. **Evaluate**: Compare costs after AWS free tier
2. **Test**: Deploy this example to test IONOS
3. **Migrate**: Plan migration when ready
4. **Optimize**: Use IONOS AI for cost savings

This example provides a complete IONOS deployment that mirrors the AWS configuration, making migration straightforward when you're ready to move from AWS free tier to a paid European solution.
