output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.asg.id
}

output "security_group_id" {
  description = "ID of the ASG security group"
  value       = aws_security_group.asg.id
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.ec2_role.name
} 