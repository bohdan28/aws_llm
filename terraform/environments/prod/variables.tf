variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to connect to bastion host"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

# ASG Configuration
variable "asg_instance_type" {
  description = "Instance type for ASG instances"
  type        = string
  default     = "t3.xlarge"
}

variable "asg_min_size" {
  description = "Minimum size of the ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of the ASG"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the ASG"
  type        = number
  default     = 2
}

# RDS Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.large"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "llmdb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

# Tags
variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "LLM Infrastructure"
    ManagedBy   = "Terraform"
  }
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for monitoring alerts"
  type        = string
}
