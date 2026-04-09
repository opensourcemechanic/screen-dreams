output "server_public_ip" {
  description = "Public IP address of the server"
  value       = ionoscloud_ipblock.screen_dreams.ips.0
}

output "server_id" {
  description = "Server ID"
  value       = ionoscloud_server.screen_dreams.id
}

output "database_hostname" {
  description = "Database hostname"
  value       = ionoscloud_database_postgresql.screen_dreams.hostname
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = ionoscloud_database_postgresql.screen_dreams.port
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = ionoscloud_s3_bucket.screen_dreams.name
}

output "ssh_command" {
  description = "SSH command to access the server"
  value       = "ssh root@${ionoscloud_ipblock.screen_dreams.ips.0}"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${ionoscloud_ipblock.screen_dreams.ips.0}"
}

output "datacenter_id" {
  description = "Datacenter ID"
  value       = ionoscloud_datacenter.screen_dreams.id
}
