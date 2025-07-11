output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_instance_endpoint
}

output "db_name" {
  description = "Name of the database"
  value       = module.database.db_name
} 