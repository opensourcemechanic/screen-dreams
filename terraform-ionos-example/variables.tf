variable "ionos_region" {
  description = "IONOS cloud region"
  type        = string
  default     = "de/fra"  # Frankfurt, Germany
}

variable "ionos_username" {
  description = "IONOS cloud username"
  type        = string
  sensitive   = true
}

variable "ionos_password" {
  description = "IONOS cloud password"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "screen-dreams"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "server_password" {
  description = "Server root password"
  type        = string
  sensitive   = true
}

# Database variables
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

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "screenwriter_db"
}

# AI Provider variables
variable "ai_provider" {
  description = "AI provider (ionos/openai/anthropic)"
  type        = string
  default     = "ionos"
}

variable "ionos_api_key" {
  description = "IONOS AI API key"
  type        = string
  sensitive   = true
  default     = ""
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

variable "secret_key" {
  description = "Flask application secret key"
  type        = string
  sensitive   = true
}
