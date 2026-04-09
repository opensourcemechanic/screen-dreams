variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "screen-dreams"
}

# Database configuration
variable "database_type" {
  description = "Database type: postgres, dynamodb, or sqlite"
  type        = string
  default     = "sqlite"
  
  validation {
    condition     = contains(["postgres", "dynamodb", "sqlite"], var.database_type)
    error_message = "Database type must be one of: postgres, dynamodb, sqlite."
  }
}

# Compute variables
variable "instance_type" {
  description = "EC2 instance type (Free Tier: t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "screen-dreams-key"
}

# Database variables
variable "db_instance_class" {
  description = "RDS instance class (Free Tier: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "screenwriter_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "screenwriter"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# AI Provider variables
variable "ai_provider" {
  description = "AI provider (openai/anthropic/ionos/scaleway)"
  type        = string
  default     = "openai"
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "anthropic_api_key" {
  description = "Anthropic API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ionos_api_key" {
  description = "IONOS API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "scaleway_api_key" {
  description = "Scaleway API key"
  type        = string
  sensitive   = true
  default     = ""
}

# Application variables
variable "secret_key" {
  description = "Flask application secret key"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

# AWS Credentials (optional - can use environment variables)
variable "aws_access_key" {
  description = "AWS access key ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS secret access key"
  type        = string
  sensitive   = true
  default     = ""
}

# Docker Build Configuration
variable "docker_build_context" {
  description = "Path to Docker build context"
  type        = string
  default     = "../"
}

variable "docker_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}
