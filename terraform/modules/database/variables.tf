variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the RDS instance"
  type        = list(string)
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.large"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "llmdb"
}

variable "master_username" {
  description = "Master username for the RDS instance"
  type        = string
}

variable "master_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "allowed_security_group_id" {
  description = "ID of the security group allowed to connect to RDS"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
} 