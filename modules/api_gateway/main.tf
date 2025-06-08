# modules/api_gateway/main.tf

# Data source to get current region
data "aws_region" "current" {}

# REST API Gateway
resource "aws_api_gateway_rest_api" "obsidian_sync_api" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API Gateway for Obsidian Sync file change events"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 🔐 API Key for authentication
resource "aws_api_gateway_api_key" "obsidian_sync_key" {
  name        = "${var.project_name}-${var.environment}-api-key"
  description = "API key for Obsidian Sync file watcher"
  enabled     = true
}

# Resource for file events (e.g., /events)
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  parent_id   = aws_api_gateway_rest_api.obsidian_sync_api.root_resource_id
  path_part   = "events"
}

# 🔐 POST method with API key required
resource "aws_api_gateway_method" "post_events" {
  rest_api_id      = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id      = aws_api_gateway_resource.events.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true # 🔐 Require API key

  request_models = {
    "application/json" = "Empty"
  }
}

# Mock integration for now (we'll replace with SQS integration later)
resource "aws_api_gateway_integration" "post_events_integration" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Method response
resource "aws_api_gateway_method_response" "post_events_200" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Integration response
resource "aws_api_gateway_integration_response" "post_events_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = aws_api_gateway_method_response.post_events_200.status_code

  response_templates = {
    "application/json" = "{\"message\": \"Event received and authenticated\"}"
  }
}

# 🔧 FIXED: Deployment (moved before usage plan)
resource "aws_api_gateway_deployment" "obsidian_sync_deployment" {
  depends_on = [
    aws_api_gateway_method.post_events,
    aws_api_gateway_integration.post_events_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id

  # Force redeploy when configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.events.id,
      aws_api_gateway_method.post_events.id,
      aws_api_gateway_integration.post_events_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "obsidian_sync_stage" {
  deployment_id = aws_api_gateway_deployment.obsidian_sync_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.obsidian_sync_api.id
  stage_name    = var.environment
}

# 🔐 FIXED: Usage Plan (now references proper stage)
resource "aws_api_gateway_usage_plan" "obsidian_sync_plan" {
  name        = "${var.project_name}-${var.environment}-usage-plan"
  description = "Usage plan for Obsidian Sync API"

  api_stages {
    api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
    stage  = aws_api_gateway_stage.obsidian_sync_stage.stage_name # 🔧 Fixed reference
  }

  quota_settings {
    limit  = var.api_quota_limit
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = var.api_rate_limit
    burst_limit = var.api_burst_limit
  }
}

# 🔐 Link API Key to Usage Plan
resource "aws_api_gateway_usage_plan_key" "obsidian_sync_plan_key" {
  key_id        = aws_api_gateway_api_key.obsidian_sync_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.obsidian_sync_plan.id
}
