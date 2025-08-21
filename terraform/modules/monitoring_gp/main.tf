# AWS Managed Grafana Workspace
resource "aws_grafana_workspace" "grafana_workspace_1" {
  name                     = "${var.environment}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana_workspace_role.arn
  tags                     = var.tags
}

resource "aws_iam_role" "grafana_workspace_role" {
  name = "grafana_workspace_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
}

# Optionally, security group for Prometheus/Grafana (if needed for VPC endpoints)
resource "aws_security_group" "monitoring" {
  name        = "${var.environment}-monitoring-sg"
  description = "Allow Prometheus and Grafana access"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

