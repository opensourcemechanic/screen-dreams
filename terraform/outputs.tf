output "public_ip" {
  description = "EC2 instance public IP address"
  value       = aws_instance.screen_dreams.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.screen_dreams.id
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = var.database_type == "postgres" ? aws_db_instance.screen_dreams[0].endpoint : "SQLite (local)"
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = var.database_type == "postgres" ? tostring(aws_db_instance.screen_dreams[0].port) : "N/A (SQLite)"
}

output "s3_bucket_name" {
  description = "S3 bucket name for file storage"
  value       = aws_s3_bucket.screen_dreams.bucket
}

output "ssh_command" {
  description = "SSH command to access the instance"
  value       = "ssh -i ${var.ssh_key_name}.pem ec2-user@${aws_instance.screen_dreams.public_ip}"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.screen_dreams.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.screen_dreams.id
}

output "security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.screen_dreams.id
}
