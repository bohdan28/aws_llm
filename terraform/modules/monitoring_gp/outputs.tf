output "grafana_workspace_id" {
  description = "ID of the Managed Grafana workspace"
  value       = aws_grafana_workspace.grafana_workspace_1.id
}

output "grafana_endpoint" {
  description = "Endpoint URL of the Managed Grafana workspace"
  value       = aws_grafana_workspace.grafana_workspace_1.endpoint
} 