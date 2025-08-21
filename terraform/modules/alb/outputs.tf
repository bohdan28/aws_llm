output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.llm_alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.llm_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.llm_target_group.arn
}
