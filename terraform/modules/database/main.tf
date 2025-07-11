# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    {
      Name        = "${var.environment}-db-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-sg"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL access from ASG security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.environment}-rds-sg"
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "14"  

  instance_class = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  auto_minor_version_upgrade = true
  deletion_protection       = false
  skip_final_snapshot      = true
  final_snapshot_identifier = "${var.environment}-postgres-final-snapshot"

  tags = merge(
    {
      Name        = "${var.environment}-postgres"
      Environment = var.environment
    },
    var.tags
  )
}
