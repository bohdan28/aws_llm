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

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = module.database.db_instance_id
}

output "asg_private_ips" {
  description = "Private IPs of ASG EC2 instances"
  value       = module.asg.asg_private_ips
}

output "asg_ids" {
  description = "List of EC2 instance IDs in the Auto Scaling Group"
  value       = module.asg.asg_ids
}

output "grafana_endpoint" {
  description = "URL of the Grafana instance"
  value       = module.monitoring_gp.grafana_endpoint
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.asg_alb.alb_dns_name
}

output "target_group_arn" {
  description = "List of target group ARNs for the ASG"
  value       = module.asg_alb.target_group_arn
}