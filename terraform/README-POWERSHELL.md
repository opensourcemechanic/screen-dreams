# PowerShell Deployment Guide

## Quick Start with PowerShell

### 1. Open PowerShell
```powershell
# Navigate to terraform directory
cd terraform
```

### 2. Validate Configuration
```powershell
# Run validation script
.\validate.ps1

# Or manually:
terraform init
terraform validate
terraform fmt -check
```

### 3. Deploy with PowerShell Script
```powershell
# Basic deployment (you'll be prompted for missing values)
.\deploy.ps1

# Full deployment with parameters
.\deploy.ps1 -SshPublicKey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..." -AiProvider "openai" -OpenAiApiKey "sk-your-key-here"
```

### 4. Manual Deployment Steps

#### Step 1: Configure Variables
```powershell
# Create terraform.tfvars
@"
region = "us-east-1"
environment = "dev"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
ai_provider = "openai"
openai_api_key = "sk-your-openai-api-key-here"
"@ | Out-File -FilePath "terraform.tfvars" -Encoding utf8
```

#### Step 2: Initialize and Plan
```powershell
terraform init
terraform plan -var-file="terraform.tfvars"
```

#### Step 3: Deploy
```powershell
terraform apply -var-file="terraform.tfvars"
```

### 5. Access Application
```powershell
# Get outputs
terraform output public_ip
terraform output application_url
terraform output ssh_command

# Test application
curl (terraform output -raw application_url)

# SSH to instance
terraform output -raw ssh_command | Invoke-Expression
```

## PowerShell Scripts

### validate.ps1
- Checks Terraform installation
- Validates AWS CLI configuration
- Initializes Terraform
- Validates configuration syntax

### deploy.ps1
- Automated deployment script
- Parameter validation
- Creates terraform.tfvars
- Runs full deployment

## Required Parameters

### SSH Public Key
Get your SSH public key:
```powershell
# If you have an existing key
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub

# Or generate a new one
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

### AI Provider API Keys
- **OpenAI**: Get from https://platform.openai.com/api-keys
- **Anthropic**: Get from https://console.anthropic.com/
- **IONOS**: Get from IONOS AI Model Hub
- **Scaleway**: Get from Scaleway Console

## Example Deployment

### Complete Command
```powershell
.\deploy.ps1 `
    -SshPublicKey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7x..." `
    -AiProvider "openai" `
    -OpenAiApiKey "sk-1234567890abcdef..." `
    -Region "us-east-1" `
    -Environment "dev"
```

### Using European AI Provider
```powershell
.\deploy.ps1 `
    -SshPublicKey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7x..." `
    -AiProvider "ionos" `
    -AnthropicApiKey "ionos-api-key-here" `
    -Region "eu-central-1"
```

## Management Commands

### Check Status
```powershell
# SSH to instance
terraform output -raw ssh_command | Invoke-Expression

# Run health check
./health-check.sh

# View logs
cd /opt/screen-dreams
docker-compose logs -f screen-dreams
```

### Update Application
```powershell
# SSH to instance
terraform output -raw ssh_command | Invoke-Expression

# Update to latest version
./update-app.sh
```

### Destroy Resources
```powershell
terraform destroy -var-file="terraform.tfvars"
```

## Troubleshooting

### Common PowerShell Issues

#### Execution Policy
```powershell
# Allow scripts to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single script
.\deploy.ps1 -ExecutionPolicy Bypass
```

#### Path Issues
```powershell
# Check Terraform path
Get-Command terraform

# Add to PATH if needed
$env:PATH += ";C:\Program Files\Terraform"
```

#### AWS CLI Issues
```powershell
# Check AWS CLI
Get-Command aws

# Configure AWS CLI
aws configure
```

### Deployment Issues

#### Instance Not Starting
```powershell
# Check instance status
aws ec2 describe-instances --instance-ids (terraform output -raw instance_id)

# Check user data logs
aws ec2 describe-instance-attribute --instance-id (terraform output -raw instance_id) --attribute userData
```

#### Application Not Responding
```powershell
# SSH to instance
terraform output -raw ssh_command | Invoke-Expression

# Check Docker status
docker ps

# Check application logs
docker-compose logs screen-dreams
```

## Cost Monitoring

### Check Free Tier Usage
```powershell
# AWS Console > Billing > Cost Explorer
# Or use AWS CLI
aws ce get-cost-and-usage --time-period Start=2023-01-01,End=2023-01-31
```

### Billing Alert
Automatic alert configured at $10/month threshold.

## Security

### SSH Key Security
- Keep your private key secure
- Use `allowed_ssh_cidr` to restrict access
- Rotate keys regularly

### API Key Security
- Never commit API keys to version control
- Use environment variables
- Rotate keys periodically

## Next Steps

1. **Deploy** using PowerShell scripts
2. **Test** all application features
3. **Configure** your AI provider
4. **Monitor** costs and usage
5. **Plan** upgrades when ready

This PowerShell deployment provides the same functionality as the Linux deployment with Windows-friendly commands and scripts.
