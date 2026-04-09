terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Random password generator for database
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$&"
}

# Random secret key for Flask
resource "random_password" "secret_key" {
  length           = 64
  special          = true
  override_special = "!#$&"
}

# CloudWatch billing alarm (to avoid unexpected costs)
resource "aws_cloudwatch_metric_alarm" "billing_alert" {
  alarm_name          = "${var.app_name}-billing-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600"  # 6 hours
  statistic           = "Maximum"
  threshold           = "10"     # Alert if charges exceed $10
  alarm_description   = "This metric monitors estimated AWS charges"
  alarm_actions       = []

  tags = {
    Name = "${var.app_name}-billing-alert"
  }
}

# Local values for commonly used configurations
locals {
  common_tags = {
    Project     = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
