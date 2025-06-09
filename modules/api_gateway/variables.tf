# modules/api_gateway/variables.tf
variable "project_name" {
  description = "Project name for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# 🔐 Security configuration
variable "api_quota_limit" {
  description = "Daily quota limit for API calls"
  type        = number
  default     = 10000
}

variable "api_rate_limit" {
  description = "API rate limit (requests per second)"
  type        = number
  default     = 100
}

variable "api_burst_limit" {
  description = "API burst limit"
  type        = number
  default     = 200
}

# Replace the existing SQS variables with these corrected ones
variable "sqs_queue_arn" {
  description = "ARN of the SQS queue to send messages to"
  type        = string
  default     = ""
}

variable "sqs_queue_url" {
  description = "URL of the SQS queue"
  type        = string
  default     = ""
}
