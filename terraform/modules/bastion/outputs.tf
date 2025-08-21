output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "bastion_instance_id" {
  description = "ID of the bastion instance"
  value       = aws_instance.bastion.id
} 