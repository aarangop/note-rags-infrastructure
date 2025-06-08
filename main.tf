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
}
