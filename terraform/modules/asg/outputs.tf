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

data "aws_instances" "asg_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.main.name
  }
  instance_state_names = ["running"]
}
 
output "asg_private_ips" {
  value = data.aws_instances.asg_instances.private_ips
}

output "asg_ids" {
  description = "List of EC2 instance IDs in the Auto Scaling Group"
  value       = data.aws_instances.asg_instances.ids
}