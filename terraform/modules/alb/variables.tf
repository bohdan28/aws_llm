variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "target_group_port" {
  description = "Port for the target group and listener"
  type        = number
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "internal" {
  description = "Whether the ALB is internal (private)"
  type        = bool
}

variable "health_check_port" {
  description = "Port for health checks"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
  default     = null
}

variable "instance_ids" {
  description = "List of instance IDs to attach to the target group"
  type        = list(string)
  default     = []  # Empty by default since you're using ASG
}
