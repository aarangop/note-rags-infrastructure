# variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile for cli access"
  type        = string
}

variable "project_name" {
  description = "Name of the project (used for tagging)"
  type        = string
  default     = "obsidian-sync"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Module enablement flags
variable "enable_s3" {
  description = "Enable S3 module"
  type        = bool
  default     = true
}

variable "enable_sqs" {
  description = "Enable SQS module"
  type        = bool
  default     = true
}

variable "enable_lambda" {
  description = "Enable Lambda module"
  type        = bool
  default     = false
}

variable "enable_iam" {
  description = "Enable IAM module"
  type        = bool
  default     = false
}

# S3-specific variables
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing vault files"
  type        = string
}

variable "enable_api_gateway" {
  description = "Enable API Gateway module"
  type        = bool
  default     = true
}
