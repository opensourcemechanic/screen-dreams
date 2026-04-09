# IONOS Cloud Terraform Example for Screen Dreams
# This is an example of how to deploy Screen Dreams on IONOS Cloud
# Use this as reference for future migration from AWS

terraform {
  required_version = ">= 1.0"
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = "~> 6.0"
    }
  }
}

provider "ionoscloud" {
  username = var.ionos_username
  password = var.ionos_password
}

# Datacenter (similar to AWS VPC)
resource "ionoscloud_datacenter" "screen_dreams" {
  name                = "screen-dreams-dc"
  location            = var.ionos_region  # e.g., "de/fra" (Frankfurt)
  description         = "Screen Dreams Datacenter"
  
  # IONOS equivalent of AWS tags
  sec_auth_dhcp = false
}

# LAN (similar to AWS VPC networking)
resource "ionoscloud_lan" "screen_dreams" {
  datacenter_id = ionoscloud_datacenter.screen_dreams.id
  name          = "screen-dreams-lan"
  public        = true  # Public LAN for internet access
}

# Server (similar to AWS EC2)
resource "ionoscloud_server" "screen_dreams" {
  name              = "screen-dreams-server"
  datacenter_id     = ionoscloud_datacenter.screen_dreams.id
  cores             = 2
  ram               = 4096  # 4GB RAM (IONOS minimum)
  availability_zone = "AUTO"
  
  # Ubuntu 22.04 image
  image_name        = "ubuntu-22.04"
  image_password    = var.server_password
  
  # Connect to LAN
  nic {
    lan             = ionoscloud_lan.screen_dreams.id
    dhcp            = true
    firewall_active = true
  }
  
  # Storage volume (similar to AWS EBS)
  volume {
    name          = "screen-dreams-storage"
    size          = 20  # 20GB
    disk_type     = "HDD"
    bus           = "VIRTIO"
    image_password = var.server_password
  }
  
  # User data for bootstrap (similar to AWS EC2 user_data)
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint      = ionoscloud_database_postgresql.screen_dreams.hostname
    db_port          = ionoscloud_database_postgresql.screen_dreams.port
    db_name          = ionoscloud_database_postgresql.screen_dreams.display_name
    db_username      = ionoscloud_database_postgresql.screen_dreams.username
    db_password      = var.db_password
    s3_bucket        = ionoscloud_s3_bucket.screen_dreams.name
    ai_provider      = var.ai_provider
    ionos_api_key    = var.ionos_api_key
    openai_api_key   = var.openai_api_key
    anthropic_api_key = var.anthropic_api_key
    secret_key       = var.secret_key
  }))
}

# Firewall Rules (similar to AWS Security Groups)
resource "ionoscloud_firewallrule" "ssh" {
  datacenter_id = ionoscloud_datacenter.screen_dreams.id
  server_id     = ionoscloud_server.screen_dreams.id
  nic_id        = ionoscloud_server.screen_dreams.nic.0.id
  name          = "ssh"
  protocol      = "TCP"
  port_range    = "22"
  source_ip     = "0.0.0.0/0"
  type          = "INGRESS"
}

resource "ionoscloud_firewallrule" "http" {
  datacenter_id = ionoscloud_datacenter.screen_dreams.id
  server_id     = ionoscloud_server.screen_dreams.id
  nic_id        = ionoscloud_server.screen_dreams.nic.0.id
  name          = "http"
  protocol      = "TCP"
  port_range    = "80"
  source_ip     = "0.0.0.0/0"
  type          = "INGRESS"
}

resource "ionoscloud_firewallrule" "https" {
  datacenter_id = ionoscloud_datacenter.screen_dreams.id
  server_id     = ionoscloud_server.screen_dreams.id
  nic_id        = ionoscloud_server.screen_dreams.nic.0.id
  name          = "https"
  protocol      = "TCP"
  port_range    = "443"
  source_ip     = "0.0.0.0/0"
  type          = "INGRESS"
}

# PostgreSQL Database (similar to AWS RDS)
resource "ionoscloud_database_postgresql" "screen_dreams" {
  datacenter_id = ionoscloud_datacenter.screen_dreams.id
  display_name  = "screen-dreams-db"
  
  # Database configuration
  postgresql_version = "14"
  cores             = 2
  ram               = 4096  # 4GB minimum
  storage_size      = 20   # 20GB
  storage_type      = "SSD"
  
  # Connection details
  username          = var.db_username
  password          = var.db_password
  database_name     = var.db_name
  
  # Location (same as datacenter)
  location          = var.ionos_region
  
  # Backup configuration
  backup_retention_period = 7  # IONOS allows backups on paid plans
  
  # Connections from server
  connections {
    datacenter_id = ionoscloud_datacenter.screen_dreams.id
    lan_id        = ionoscloud_lan.screen_dreams.id
    ip            = ionoscloud_server.screen_dreams.nic.0.ips.0
  }
}

# S3 Bucket (similar to AWS S3)
resource "ionoscloud_s3_bucket" "screen_dreams" {
  name           = "${var.app_name}-${random_id.bucket_suffix.hex}"
  region         = var.ionos_region
  
  # Bucket configuration
  versioning     = false  # Disabled for cost savings
  public_access  = false  # Private bucket
  
  # Lifecycle rules
  lifecycle_rule {
    id     = "delete_old_uploads"
    status = "Enabled"
    filter {
      prefix = "uploads/"
    }
    expiration {
      days = 30
    }
  }
  
  lifecycle_rule {
    id     = "delete_old_screenplays"
    status = "Enabled"
    filter {
      prefix = "screenplays/"
    }
    expiration {
      days = 90
    }
  }
}

# IP Block (for static IP)
resource "ionoscloud_ipblock" "screen_dreams" {
  name     = "screen-dreams-ip"
  location = var.ionos_region
  size     = 1  # Single IP address
}

# Assign IP to server
resource "ionoscloud_ipblock_reservation" "screen_dreams" {
  datacenter_id = ionoscloud_datacenter.screen_dreams.id
  server_id     = ionoscloud_server.screen_dreams.id
  nic_id        = ionoscloud_server.screen_dreams.nic.0.id
  ip            = ionoscloud_ipblock.screen_dreams.ips.0
}

# Random ID for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 8
}
