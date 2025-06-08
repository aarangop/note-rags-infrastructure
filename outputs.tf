# outputs.tf
output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = var.enable_s3 ? module.s3[0].bucket_name : null
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = var.enable_s3 ? module.s3[0].bucket_arn : null
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = var.enable_api_gateway ? module.api_gateway[0].api_url : null
}

output "events_endpoint" {
  description = "Full URL for the events endpoint"
  value       = var.enable_api_gateway ? module.api_gateway[0].events_endpoint : null
}

# Add to existing outputs.tf

# 🔐 API Key outputs (sensitive)
output "api_key_id" {
  description = "API Key ID"
  value       = var.enable_api_gateway ? module.api_gateway[0].api_key_id : null
}

output "api_key_value" {
  description = "API Key Value (use this in requests)"
  value       = var.enable_api_gateway ? module.api_gateway[0].api_key_value : null
  sensitive   = true
}
