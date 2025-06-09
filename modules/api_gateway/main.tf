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

# 🔗 IAM role for API Gateway to write to SQS
resource "aws_iam_role" "apigateway_sqs_role" {
  name = "${var.project_name}-${var.environment}-apigateway-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy to allow sending messages to SQS
resource "aws_iam_role_policy" "apigateway_sqs_policy" {
  name = "${var.project_name}-${var.environment}-apigateway-sqs-policy"
  role = aws_iam_role.apigateway_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })
}

# Add this IAM role for CloudWatch logging
resource "aws_iam_role" "apigateway_cloudwatch_role" {
  name = "${var.project_name}-${var.environment}-apigateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for CloudWatch logs
resource "aws_iam_role_policy_attachment" "apigateway_cloudwatch_policy" {
  role       = aws_iam_role.apigateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Account-level API Gateway CloudWatch role (only needs to be set once per account)
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_role.arn
}

# 🔗 SQS integration
resource "aws_api_gateway_integration" "post_events_integration" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path//"
  credentials             = aws_iam_role.apigateway_sqs_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&QueueUrl=${var.sqs_queue_url}&MessageBody=$util.urlEncode($input.body)"
  }
}

# Method response for 200 (what we return to client)
resource "aws_api_gateway_method_response" "post_events_200" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# 🔧 Integration response for SQS
resource "aws_api_gateway_integration_response" "post_events_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = "200"
  # Matches responses with MessageId in their body (SQS returns an XML object)
  selection_pattern = ""

  response_templates = {
    "application/json" = jsonencode({
      message    = "Event sent to queue successfully"
      timestamp  = "$context.requestTime",
      request_id = "$context.requestId"
    })
  }

  depends_on = [aws_api_gateway_integration.post_events_integration]
}
# Method response for 200 (what we return to client)
resource "aws_api_gateway_method_response" "post_events_400" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = "400"

  response_models = {
    "application/json" = "Empty"
  }
}

# Error response for SQS failures
resource "aws_api_gateway_integration_response" "post_events_integration_response_400" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = "400"

  # Match SQS error responses
  selection_pattern = ".*Error.*|.*Exception.*|.*error.*"

  response_templates = {
    "application/json" = jsonencode({
      error     = "Failed to send message to queue"
      timestamp = "$context.requestTime"
    })
  }

  depends_on = [aws_api_gateway_integration.post_events_integration]
}

# Method response for 200 (what we return to client)
resource "aws_api_gateway_method_response" "post_events_500" {
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post_events.http_method
  status_code = "500"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_deployment" "obsidian_sync_deployment" {
  depends_on = [
    aws_api_gateway_method.post_events,
    aws_api_gateway_integration.post_events_integration,
    aws_api_gateway_integration_response.post_events_integration_response_200,
    aws_api_gateway_integration_response.post_events_integration_response_400,
  ]

  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id

  # Force redeploy when configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.events.id,
      aws_api_gateway_method.post_events.id,
      aws_api_gateway_integration.post_events_integration.id,
      aws_api_gateway_integration_response.post_events_integration_response_200.id,
      aws_api_gateway_integration_response.post_events_integration_response_400.id,
      timestamp()
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "obsidian_sync_stage" {
  depends_on = [
    aws_api_gateway_account.api_gateway_account,
    aws_cloudwatch_log_group.api_gateway_logs
  ]

  deployment_id = aws_api_gateway_deployment.obsidian_sync_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.obsidian_sync_api.id
  stage_name    = var.environment

  # 📝 Enable logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      caller             = "$context.identity.caller"
      user               = "$context.identity.user"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      resourcePath       = "$context.resourcePath"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLength     = "$context.responseLength"
      error              = "$context.error.message"
      integrationError   = "$context.integration.error"
      integrationStatus  = "$context.integration.status"
      integrationLatency = "$context.integration.latency"
      responseLatency    = "$context.responseLatency"
    })
  }
}

# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

# Add this after the stage resource
resource "aws_api_gateway_method_settings" "general_settings" {
  depends_on = [
    aws_api_gateway_account.api_gateway_account,
    aws_api_gateway_stage.obsidian_sync_stage
  ]
  rest_api_id = aws_api_gateway_rest_api.obsidian_sync_api.id
  stage_name  = aws_api_gateway_stage.obsidian_sync_stage.stage_name
  method_path = "*/*"

  settings {
    # Enable detailed CloudWatch metrics
    metrics_enabled = true

    # Enable full request/response logging
    logging_level = "INFO"

    # Log full requests and responses
    data_trace_enabled = true

    # Throttling settings
    throttling_rate_limit  = var.api_rate_limit
    throttling_burst_limit = var.api_burst_limit
  }
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
