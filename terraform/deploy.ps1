# PowerShell script to deploy Screen Dreams to AWS
param(
    [string]$Region = "us-east-1",
    [string]$Environment = "dev",
    [string]$SshPublicKey = "",
    [string]$AiProvider = "openai",
    [string]$OpenAiApiKey = "",
    [string]$AnthropicApiKey = ""
)

Write-Host "=== Screen Dreams AWS Deployment ===" -ForegroundColor Green

# Check prerequisites
if (-not $SshPublicKey) {
    Write-Host "Error: SSH public key required" -ForegroundColor Red
    Write-Host "Usage: .\deploy.ps1 -SshPublicKey 'ssh-rsa AAAAB...'" -ForegroundColor Yellow
    exit 1
}

if ($AiProvider -eq "openai" -and -not $OpenAiApiKey) {
    Write-Host "Error: OpenAI API key required when using OpenAI provider" -ForegroundColor Red
    exit 1
}

# Create terraform.tfvars file
$tfvarsContent = @"
# AWS Configuration
region = "$Region"
environment = "$Environment"

# SSH Configuration
ssh_public_key = "$SshPublicKey"
ssh_key_name = "screen-dreams-key"
allowed_ssh_cidr = "0.0.0.0/0"

# AI Provider Configuration
ai_provider = "$AiProvider"
openai_api_key = "$OpenAiApiKey"
anthropic_api_key = "$AnthropicApiKey"
"@

Write-Host "Creating terraform.tfvars..." -ForegroundColor Yellow
$tfvarsContent | Out-File -FilePath "terraform.tfvars" -Encoding utf8

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Plan deployment
Write-Host "Planning deployment..." -ForegroundColor Yellow
terraform plan -var-file="terraform.tfvars"

# Ask for confirmation
$confirmation = Read-Host "Continue with deployment? (y/n)"
if ($confirmation -ne "y") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Apply deployment
Write-Host "Applying deployment..." -ForegroundColor Yellow
terraform apply -var-file="terraform.tfvars" -auto-approve

# Get outputs
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
$publicIp = terraform output -raw public_ip
$sshCommand = terraform output -raw ssh_command
$appUrl = terraform output -raw application_url

Write-Host "Public IP: $publicIp" -ForegroundColor Cyan
Write-Host "Application URL: $appUrl" -ForegroundColor Cyan
Write-Host "SSH Command: $sshCommand" -ForegroundColor Cyan

Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Wait 2-3 minutes for application to start" -ForegroundColor Yellow
Write-Host "2. Test application: curl $appUrl" -ForegroundColor Yellow
Write-Host "3. SSH to instance: $sshCommand" -ForegroundColor Yellow
Write-Host "4. Check status: ./health-check.sh" -ForegroundColor Yellow
