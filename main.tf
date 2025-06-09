# main.tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# S3 Module - conditionally enabled
module "s3" {
  count  = var.enable_s3 ? 1 : 0
  source = "./modules/s3"

  bucket_name  = var.s3_bucket_name
  project_name = var.project_name
  environment  = var.environment
}

# Add this to your existing main.tf after the S3 module

# API Gateway Module - conditionally enabled
module "api_gateway" {
  count  = var.enable_api_gateway ? 1 : 0
  source = "./modules/api_gateway"

  project_name = var.project_name
  environment  = var.environment

  # 🔗 Pass SQS info to API Gateway
  sqs_queue_arn = var.enable_sqs ? module.sqs[0].queue_arn : ""
  sqs_queue_url = var.enable_sqs ? module.sqs[0].queue_url : ""
}

# SQS Module - conditionally enabled
module "sqs" {
  count  = var.enable_sqs ? 1 : 0
  source = "./modules/sqs"

  project_name = var.project_name
  environment  = var.environment
}
