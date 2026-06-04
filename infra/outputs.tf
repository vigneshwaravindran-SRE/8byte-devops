output "instance_id" {
  description = "EC2 instance ID (use with SSM to connect)"
  value       = aws_instance.bytesapp.id
}

output "alb_dns_name" {
  description = "will hit this to reach the app, it will route to EC2 instance"
  value       = aws_lb.albapp.dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.rdsinstance.address
  sensitive   = true 
}