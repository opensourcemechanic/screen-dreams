provider "aws" {
  region = var.region
  
  # Use environment variables or default profile
  access_key = var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_secret_key != "" ? var.aws_secret_key : null
  
  default_tags {
    tags = {
      Project     = "screen-dreams"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
