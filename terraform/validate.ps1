# PowerShell script to validate Terraform configuration
Write-Host "=== Screen Dreams Terraform Validation ===" -ForegroundColor Green

# Check if Terraform is installed
try {
    $terraformVersion = terraform version
    Write-Host "Terraform found:" -ForegroundColor Green
    Write-Host $terraformVersion
} catch {
    Write-Host "Error: Terraform not found in PATH" -ForegroundColor Red
    Write-Host "Please install Terraform and add to PATH" -ForegroundColor Yellow
    exit 1
}

# Check if AWS CLI is configured
try {
    $awsUser = aws sts get-caller-identity --query Account --output text
    Write-Host "AWS CLI configured for account: $awsUser" -ForegroundColor Green
} catch {
    Write-Host "Error: AWS CLI not configured" -ForegroundColor Red
    Write-Host "Please run 'aws configure' first" -ForegroundColor Yellow
    exit 1
}

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Validate configuration
Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow
terraform validate

# Format check
Write-Host "Checking Terraform formatting..." -ForegroundColor Yellow
terraform fmt -check

Write-Host "=== Validation Complete ===" -ForegroundColor Green
Write-Host "Ready to run: terraform plan" -ForegroundColor Cyan
