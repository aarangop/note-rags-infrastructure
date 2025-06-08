# modules/api_gateway/outputs.tf
output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.obsidian_sync_api.id
}

output "api_arn" {
  description = "ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.obsidian_sync_api.arn
}

output "api_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.obsidian_sync_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}"
}

output "events_endpoint" {
  description = "Full URL for the events endpoint"
  value       = "https://${aws_api_gateway_rest_api.obsidian_sync_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}/events"
}

# 🔐 API Key (sensitive)
output "api_key_id" {
  description = "ID of the API key"
  value       = aws_api_gateway_api_key.obsidian_sync_key.id
}

output "api_key_value" {
  description = "Value of the API key"
  value       = aws_api_gateway_api_key.obsidian_sync_key.value
  sensitive   = true
}

output "base_url_components" {
  description = "Components to build the URL manually"
  value = {
    api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
    region = data.aws_region.current.name
    stage  = var.environment
  }
}
