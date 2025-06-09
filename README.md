# Obsidian Infrastructure

Terraform modules for deploying AWS infrastructure supporting an Obsidian vault
RAG (Retrieval-Augmented Generation) system. Provides scalable, secure, and
cost-effective cloud infrastructure for AI-powered knowledge systems.

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│ File Watcher    │───▶│ API Gateway  │───▶│ SQS Queue   │───▶│ Lambda       │
│ (obsidian-sync) │    │ + Auth       │    │ + DLQ       │    │ Processing   │
└─────────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
                                                                       │
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐           │
│ Vector Database │◀───│ S3 Storage   │◀───│ File        │◀──────────┘
│ (OpenSearch)    │    │ + Versioning │    │ Processing  │
└─────────────────┘    └──────────────┘    └─────────────┘
```

## Features

### 🔐 **Security First**

- API Gateway with API key authentication
- IAM roles with least-privilege access
- S3 bucket with encryption and private access
- VPC endpoints for private communication (optional)

### 📡 **Event-Driven Architecture**

- Direct API Gateway → SQS integration (no Lambda cold starts)
- Dead letter queues for failed message handling
- CloudWatch monitoring and alerting

### 🏗️ **Modular Design**

- Independent Terraform modules
- Conditional resource deployment
- Environment-specific configurations
- Easy to extend and modify

### 📊 **Observability**

- Comprehensive CloudWatch logging
- API Gateway access logs and execution logs
- SQS metrics and dead letter queue monitoring
- Cost tracking with resource tagging

## Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Terraform** 1.0 or higher
- **AWS Account** with permissions for:
  - IAM (roles, policies)
  - API Gateway
  - SQS
  - S3
  - CloudWatch Logs
  - Lambda (for future modules)

## Quick Start

1. **Clone the repository:**

```bash
git clone https://github.com/yourusername/obsidian-infrastructure.git
cd obsidian-infrastructure
```

2. **Configure your variables:**

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

3. **Deploy the infrastructure:**

```bash
terraform init
terraform plan
terraform apply
```

4. **Get your API credentials:**

```bash
terraform output api_key_value
terraform output api_gateway_components
```

## Configuration

### Required Variables

```hcl
# terraform.tfvars
aws_region      = "us-east-1"
aws_profile     = "your-aws-profile"
project_name    = "obsidian-sync"
environment     = "dev"

# S3 configuration
s3_bucket_name  = "your-unique-obsidian-sync-bucket-name"

# Module enablement
enable_s3           = true
enable_sqs          = true
enable_api_gateway  = true
enable_lambda       = false  # Future use
enable_iam          = false  # Future use
```

### Optional Variables

```hcl
# API Gateway settings
api_quota_limit    = 10000  # Daily quota
api_rate_limit     = 100    # Requests per second
api_burst_limit    = 200    # Burst capacity

# SQS settings
max_receive_count  = 3      # Before moving to DLQ
```

## Modules

### 📁 **S3 Module** (`modules/s3/`)

- **Purpose**: Store Obsidian vault files and processed content
- **Features**: Versioning, encryption, lifecycle policies
- **Resources**: S3 bucket, bucket policies, lifecycle rules

### 🚀 **API Gateway Module** (`modules/api_gateway/`)

- **Purpose**: Secure HTTP endpoint for file change events
- **Features**: API key auth, rate limiting, CloudWatch logging
- **Resources**: REST API, resources, methods, deployment, stage

### 📬 **SQS Module** (`modules/sqs/`)

- **Purpose**: Reliable message queuing for file processing
- **Features**: Dead letter queue, long polling, encryption
- **Resources**: Main queue, DLQ, queue policies

### 🔧 **Lambda Module** (`modules/lambda/`) - _Coming Soon_

- **Purpose**: Process files and generate embeddings
- **Features**: Auto-scaling, error handling, monitoring
- **Resources**: Lambda functions, roles, triggers

### 🔑 **IAM Module** (`modules/iam/`) - _Coming Soon_

- **Purpose**: Centralized IAM role and policy management
- **Features**: Cross-service permissions, least privilege
- **Resources**: Roles, policies, policy attachments

## Deployment

### Environment-Specific Deployments

```bash
# Development environment
terraform workspace new dev
terraform apply -var-file="environments/dev.tfvars"

# Production environment
terraform workspace new prod
terraform apply -var-file="environments/prod.tfvars"
```

### Selective Module Deployment

```bash
# Deploy only S3 and SQS
terraform apply -var="enable_api_gateway=false"

# Deploy everything except Lambda
terraform apply -var="enable_lambda=false"
```

### Destroy Infrastructure

```bash
# Destroy specific modules
terraform destroy -target=module.api_gateway

# Destroy everything
terraform destroy
```

## Outputs

After deployment, access important values:

```bash
# API Gateway information
terraform output api_gateway_components
terraform output api_key_value

# SQS information
terraform output sqs_queue_url
terraform output sqs_queue_arn

# S3 information
terraform output s3_bucket_name
```

## Cost Optimization

### Estimated Monthly Costs (us-east-1)

| Service         | Usage                  | Estimated Cost   |
| --------------- | ---------------------- | ---------------- |
| API Gateway     | 10K requests/day       | $0.35            |
| SQS             | 300K messages/month    | $0.12            |
| S3              | 1GB storage + requests | $0.25            |
| CloudWatch Logs | 1GB/month              | $0.50            |
| **Total**       |                        | **~$1.22/month** |

### Cost Optimization Features

- **S3 Lifecycle Policies**: Automatic transition to cheaper storage classes
- **SQS Long Polling**: Reduces empty receive costs
- **CloudWatch Log Retention**: Automatic log cleanup after 7 days
- **Regional Deployment**: Keep all resources in same region

## Monitoring

### CloudWatch Dashboards

The infrastructure includes monitoring for:

- API Gateway request rates and errors
- SQS queue depth and processing times
- S3 storage metrics and costs
- Lambda function performance (when deployed)

### Alerting

Set up alerts for:

- API Gateway 4xx/5xx error rates > 5%
- SQS dead letter queue messages > 0
- S3 costs exceeding budget
- Lambda function errors > 1%

## Security Considerations

### Network Security

- All resources deployed in default VPC with security groups
- S3 bucket blocks all public access
- API Gateway uses regional endpoints

### Access Control

- API keys for external access
- IAM roles for service-to-service communication
- Least privilege principle for all permissions

### Data Protection

- S3 server-side encryption enabled
- SQS message encryption in transit
- CloudWatch logs encrypted

## Troubleshooting

### Common Issues

**Terraform Apply Fails**

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify region and profile
terraform plan
```

**API Gateway Integration Errors**

```bash
# Check CloudWatch logs
aws logs filter-log-events \
  --log-group-name "/aws/apigateway/obsidian-sync-dev" \
  --start-time $(date -d '5 minutes ago' +%s)000
```

**S3 Bucket Name Conflicts**

- S3 bucket names must be globally unique
- Update `s3_bucket_name` in terraform.tfvars

### Debug Mode

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
terraform apply
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-module`)
3. Test your changes thoroughly
4. Update documentation
5. Submit a pull request

### Module Development Guidelines

- Follow Terraform best practices
- Include comprehensive variable descriptions
- Provide meaningful outputs
- Add proper resource tagging
- Include validation where appropriate

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## Related Projects

- [obsidian-sync](../obsidian-sync) - Go file watcher for monitoring vault
  changes
- [obsidian-pipeline](../obsidian-pipeline) - Lambda functions for file
  processing and embedding generation
