# ChatOps Terraform Module v0.1.0

A Terraform module for building ChatOps workflows on AWS. This module enables you to manage infrastructure through Telegram with secure GitHub Actions integration.

## Architecture
 
```
┌─────────────────────────────────────────────────────────────────┐
│                         ChatOps v0.1.0                            │
│                                                                 │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐         │
│  │    Core      │   │    CI/CD     │   │     Chat     │         │
│  │              │   │              │   │              │         │
│  │  • Secrets   │   │  • GitHub    │   │  • Telegram  │         │
│  │  • Webhook   │   │    OIDC      │   │              │         │
│  │    Handler   │   │  • IAM       │   │              │         │
│  │  • AI        │   │              │   │              │         │
│  │    Processor │   │              │   │              │         │
│  └──────────────┘   └──────────────┘   └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## ⚠️ Important: Tag Requirement for Resource Management

**All resources that you want to manage via ChatOps must be tagged with `ChatOpsManaged = "true"`.**

The GitHub Actions IAM role can only destroy resources that have this tag. This is a security feature to prevent accidental destruction of untagged resources.

### Quick Start

Add the tag to your resources:

```hcl
resource "aws_instance" "example" {
  # ... other configuration ...
  
  tags = {
    Name        = "my-instance"
    ChatOpsManaged = "true"  # Required for ChatOps management
  }
}
```

### Advanced Configuration

The tag key and value are configurable via module variables:
- `resource_tag_key` (default: `"ChatOpsManaged"`)
- `resource_tag_value` (default: `"true"`)

### Supported Resource Types

The tag-based IAM policy supports all standard AWS resource types that can be tagged. Common resources include:
- EC2 instances and security groups
- RDS databases
- S3 buckets
- Lambda functions
- API Gateways
- VPCs and subnets
- And many more...

### Best Practices

1. **Always tag resources**: Add the tag when creating resources
2. **Use consistent tagging**: Use the default tag values for consistency
3. **Tag modules**: If using modules, ensure tags are passed through
4. **Verify tags**: Use `terraform state show` to verify tags before using ChatOps

For detailed tag management documentation, see [Tag Management](#tag-management) section below.

## Features

- **Telegram Integration**: Full bot integration with chat authorization
- **Secure CI/CD Integration**: GitHub OIDC authentication with least-privilege IAM
- **Centralized Secret Management**: AWS Secrets Manager for all credentials
- **Separate AI Processing**: Optional AWS Bedrock integration for output summarization
- **Observability**: CloudWatch logging, X-Ray tracing, API throttling
- **Modular Architecture**: Core module + optional AI processor

## Quick Start

See the [examples/](examples/) directory for complete usage examples:

- **[examples/basic/](examples/basic/)** - Basic Telegram + GitHub integration
- **[examples/with-ai/](examples/with-ai/)** - With AI output processing  
- **[examples/with-security/](examples/with-security/)** - Enterprise security monitoring

## Module Structure

```
terraform-aws-chatops/
├── main.tf                          # Root module orchestration
├── variables.tf                     # User-facing inputs
├── outputs.tf                       # Module outputs
├── versions.tf                      # Provider requirements
│
├── modules/
│   ├── core/
│   │   ├── secrets/                 # Centralized secret management
│   │   ├── webhook-handler/         # Main webhook processor
│   │   └── ai-output-processor/     # Core: AI output processing
│   ├── cicd/
│   │   └── github/                  # GitHub OIDC + IAM
│   └── chat/
│       └── telegram/                # Telegram bot integration
│
└── examples/
    ├── basic/                       # Telegram + GitHub (no AI)
    ├── with-ai/                     # Telegram + GitHub + AI processor
    └── with-security/               # Enterprise security monitoring
```

## 🔒 Security Features

### **Optional Security Monitoring**
The module includes optional enterprise-grade security monitoring:

```hcl
module "chatops" {
  source = "github.com/your-org/terraform-aws-chatops"
  
  # ... other variables
  
  # 🔒 Enable security alarms and enhanced logging
  enable_security_alarms = true
}
```

### **Security Features (When Enabled)**
- **CloudWatch Security Alarms** - DDoS detection, attack monitoring, cost control
- **Enhanced Logging** - Security-focused log groups with 7-day retention
- **SNS Notifications** - Real-time alerts for security events
- **Request Validation** - API Gateway request validation and filtering

### **Cost Impact**
- **Security Disabled**: $6.80/month (default)
- **Security Enabled**: $9.80/month (+$3/month for security monitoring)

See [examples/with-security/](examples/with-security/) for detailed security configuration.

## Cost Breakdown

### Monthly Cost Estimates

The ChatOps module has minimal infrastructure costs. Here's a breakdown by configuration:

| Configuration | Monthly Cost | Components |
|---------------|--------------|------------|
| **Basic** (no AI, no security) | ~$6.80 | Lambda, API Gateway, Secrets Manager, CloudWatch Logs |
| **With AI** | ~$7.80 | Basic + AI processor Lambda + Bedrock usage |
| **With Security** | ~$9.80 | Basic + Security alarms + SNS + Enhanced logging |
| **Full** (AI + Security) | ~$10.80 | All features enabled |

### Cost Components

#### Base Infrastructure (All Configurations)
- **Lambda Functions** (2 functions):
  - Invocations: First 1M requests/month free, then $0.20 per 1M requests
  - Compute: $0.0000166667 per GB-second
  - Estimated: ~$2.00/month (10K invocations/month, 256MB memory, 500ms average)
- **API Gateway**:
  - Requests: First 1M requests/month free, then $3.50 per 1M requests
  - Estimated: ~$0.50/month (10K requests/month)
- **Secrets Manager**:
  - Secrets: $0.40 per secret per month
  - API Calls: $0.05 per 10,000 calls
  - Estimated: ~$1.20/month (2 secrets, 10K API calls/month)
- **CloudWatch Logs**:
  - Ingestion: $0.50 per GB
  - Storage: $0.03 per GB/month
  - Estimated: ~$1.00/month (7-day retention, ~1GB logs/month)
- **SQS Dead Letter Queue**:
  - Requests: First 1M requests/month free, then $0.40 per 1M requests
  - Estimated: ~$0.10/month (minimal usage)
- **Total Base**: ~$6.80/month

#### AI Processing (Optional)
- **AI Processor Lambda**:
  - Invocations: ~$1.00/month (10K invocations/month)
  - **AWS Bedrock** (Amazon Titan Text Express):
    - Input tokens: $0.0002 per 1K tokens
    - Output tokens: $0.0003 per 1K tokens
    - Estimated: ~$0.50/month (5K input tokens, 1K output tokens per invocation, 10K invocations/month)
- **Total AI**: ~$1.50/month

#### Security Monitoring (Optional)
- **SNS Notifications**:
  - First 1M notifications/month free, then $0.50 per 1M notifications
  - Estimated: ~$0.50/month (minimal usage)
- **CloudWatch Alarms**:
  - $0.10 per alarm per month
  - Estimated: ~$0.60/month (6 alarms)
- **Enhanced Logging**:
  - Additional log retention and ingestion
  - Estimated: ~$0.50/month
- **Total Security**: ~$1.60/month

### Cost Optimization Tips

1. **Log Retention**: Default 7-day retention is cost-effective. Increase only if needed.
2. **Lambda Memory**: Use minimum memory (128MB) unless performance requires more.
3. **Lambda Timeout**: Set appropriate timeout (30s default) to avoid unnecessary compute time.
4. **API Gateway Caching**: Not applicable for Lambda-backed APIs (webhooks require real-time processing).
5. **Reserved Concurrency**: Default 10 reserved concurrent executions prevents runaway costs.
6. **AI Processing**: Disable AI processing if not needed to save ~$1.50/month.
7. **Security Alarms**: Disable security alarms if not needed to save ~$1.60/month.

### Detailed Cost Analysis

For detailed cost breakdowns, pricing calculations, and cost optimization strategies, see [Cost Analysis Documentation](docs/COST_ANALYSIS.md).

## Network Architecture (VPC)

### Why VPC is Not Required

The ChatOps module does **not** use VPC configuration for Lambda functions. This is intentional and cost-effective:

#### 1. Public AWS Services Access
- Lambda functions access **public AWS services**:
  - Secrets Manager (public endpoint)
  - SQS (public endpoint)
  - CloudWatch Logs (public endpoint)
  - AWS Bedrock (public endpoint)
- These services are accessible from the internet and don't require VPC endpoints.

#### 2. Public API Access
- Lambda functions access **public APIs**:
  - GitHub API (public internet)
  - Telegram Bot API (public internet)
- These APIs are accessible from the internet and don't require VPC configuration.

#### 3. Cost Considerations
- **VPC Configuration Costs**:
  - NAT Gateway: ~$32/month + data transfer costs
  - VPC Endpoints: ~$7/month per endpoint + data transfer costs
  - Additional complexity and maintenance
- **Without VPC**: No additional network costs, simpler architecture

#### 4. Security Considerations
- **API Gateway Security**: API Gateway handles public access and authentication
- **API Key Authentication**: Optional API key authentication provides additional security
- **IAM Policies**: Least-privilege IAM policies restrict Lambda access
- **Secrets Manager**: Credentials stored securely in Secrets Manager

#### 5. When VPC Might Be Needed
- **Private Resources**: If Lambda needs to access private resources (RDS, ElastiCache, etc.)
- **Compliance Requirements**: If compliance mandates VPC configuration
- **Network Isolation**: If network isolation is required for security

**Note**: If VPC is required, users can add VPC configuration in their own Terraform configuration. The module doesn't prevent VPC usage, but doesn't configure it by default.

### Network Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                               │
└─────────────────────────────────────────────────────────┘
                          │
                          │ HTTPS
                          ▼
┌─────────────────────────────────────────────────────────┐
│              API Gateway (Public)                        │
│  - Request validation                                   │
│  - API key authentication (optional)                    │
│  - Rate limiting                                        │
└─────────────────────────────────────────────────────────┘
                          │
                          │ Invoke
                          ▼
┌─────────────────────────────────────────────────────────┐
│         Lambda Functions (No VPC)                        │
│  ┌──────────────────┐  ┌──────────────────┐           │
│  │ Webhook Handler  │  │ Telegram Bot     │           │
│  └──────────────────┘  └──────────────────┘           │
│                          │                               │
│                          ▼                               │
│                  ┌──────────────────┐                    │
│                  │ AI Processor     │                    │
│                  └──────────────────┘                    │
└─────────────────────────────────────────────────────────┘
         │              │              │              │
         │              │              │              │
         ▼              ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   Secrets   │ │     SQS     │ │ CloudWatch  │ │   Bedrock   │
│   Manager   │ │     DLQ     │ │    Logs     │ │     AI      │
│  (Public)   │ │  (Public)   │ │  (Public)   │ │  (Public)   │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
         │              │              │              │
         │              │              │              │
         ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────────┐
│              Public Internet APIs                        │
│  - GitHub API                                           │
│  - Telegram Bot API                                     │
└─────────────────────────────────────────────────────────┘
```

**Key Points:**
- All Lambda functions access public AWS services (no VPC needed)
- All Lambda functions access public internet APIs (no VPC needed)
- API Gateway handles public access and authentication
- No NAT Gateway or VPC endpoints required
- Simpler architecture, lower cost

## Retry Behavior and Error Handling

**Important:** Retry logic is implemented in the Lambda code (separate repository), not in Terraform. The module provides infrastructure (DLQ, IAM permissions) for retry handling.

### Recommended Retry Patterns

- **GitHub API Calls**: Exponential backoff, retry on rate limits (429) and server errors (5XX)
- **Telegram API Calls**: Exponential backoff, retry on rate limits (429) and server errors (5XX)
- **Secrets Manager**: Retry with exponential backoff for transient failures
- **Dead Letter Queue**: Failed invocations are sent to DLQ after Lambda retries are exhausted

### Lambda Code Repository

The actual retry logic implementation should be in the Lambda code repository. This module only provides the infrastructure for retry handling.

**Reference Implementation:**
- Lambda code repository: [chatops-state-manager](https://github.com/BarryPekerman/chatops-state-manager)
- See Lambda code for actual retry implementation

For more details, see [Development Documentation](docs/DEVELOPMENT.md#retry-behavior-and-error-handling).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 6.0 |
| random | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 6.0 |
| random | ~> 3.6 |

## Inputs

### Required Variables

| Name                      | Description                             | Type     |
|---------------------------|-----------------------------------------|----------|
| name_prefix               | Prefix for resource names               | `string` |
| github_owner              | GitHub repository owner/organization    | `string` |
| github_repo               | GitHub repository name                  | `string` |
| github_token              | GitHub personal access token            | `string` |
| telegram_bot_token        | Telegram bot token                      | `string` |
| authorized_chat_id        | Authorized Telegram chat ID             | `string` |
| s3_bucket_arn             | ARN of S3 bucket for Terraform state    | `string` |
| webhook_lambda_zip_path   | Path to webhook handler Lambda ZIP file | `string` |
| telegram_lambda_zip_path  | Path to Telegram bot Lambda ZIP file    | `string` |

### Optional Variables

| Name                     | Description | Type | Default |
|--------------------------|-------------|------|---------|
| github_branch            | GitHub branch for OIDC authentication      | `string` | `"main"` |
| max_message_length       | Maximum message length (simple truncation) | `number` | `3500`   |
| api_gateway_stage        | API Gateway stage name                     | `string` | `"prod"` |
| log_retention_days       | CloudWatch log retention in days           | `number` | `7`      |
| enable_xray_tracing      | Enable X-Ray tracing for API Gateway       | `bool`   | `true`   |
| rate_limit               | API Gateway rate limit (requests/second)   | `number` | `100`    |
| burst_limit              | API Gateway burst limit                    | `number` | `200`    |
| quota_limit              | API Gateway quota limit                    | `number` | `10000`  |
| quota_period             | API Gateway quota period                   | `string` | `"DAY"`  |
| webhook_api_key_required | Whether webhook API requires API key       | `bool`   | `false`  |
| enable_security_alarms   | Enable CloudWatch security alarms and enhanced logging | `bool` | `false` |
| tags                     | Tags to apply to all resources             | `map(string)` | `{"ManagedBy": "terraform", "Project": "chatops"}` |

## Outputs

| Name                       | Description                         |
|----------------------------|-------------------------------------|
| secrets_manager_arn        | ARN of the Secrets Manager secret   |
| secrets_manager_name       | Name of the Secrets Manager secret  |
| webhook_url                | Webhook API Gateway URL             |
| webhook_api_key            | Webhook API key (if enabled)        |
| webhook_function_arn       | ARN of the webhook handler Lambda   |
| github_role_arn            | ARN of the GitHub Actions IAM role  |
| github_role_name           | Name of the GitHub Actions IAM role |
| oidc_provider_arn          | ARN of the GitHub OIDC provider     |
| telegram_bot_function_arn  | ARN of the Telegram bot Lambda      |
| telegram_bot_function_name | Name of the Telegram bot Lambda     |

## Platform Support

### Telegram (v0.1.0)

- ✅ Bot integration
- ✅ Webhook handler
- ✅ Chat ID authorization
- ✅ Message truncation
- ✅ API Gateway integration

## Tag Management

### Overview

ChatOps uses tag-based IAM policies to ensure only properly tagged resources can be managed. This prevents accidental destruction of untagged resources.

### Required Tag

**Tag Key**: `ChatOpsManaged` (configurable via `resource_tag_key` variable)  
**Tag Value**: `"true"` (configurable via `resource_tag_value` variable)

### Tagging Resources

#### Basic Resource Tagging

```hcl
resource "aws_instance" "example" {
  # ... configuration ...
  
  tags = {
    Name           = "my-instance"
    ChatOpsManaged = "true"  # Required for ChatOps destroy operations
  }
}
```

#### Tagging Modules

When using modules, ensure tags are passed through:

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  # ... VPC configuration ...
  
  tags = {
    Name           = "my-vpc"
    ChatOpsManaged = "true"  # Passed to all VPC resources
  }
}
```

#### Tagging Multiple Resources

Use a common tags variable:

```hcl
locals {
  common_tags = {
    Environment    = "production"
    ChatOpsManaged = "true"
  }
}

resource "aws_instance" "web" {
  tags = local.common_tags
}

resource "aws_security_group" "web_sg" {
  tags = local.common_tags
}
```

### Verifying Tags

Before using ChatOps, verify your resources are tagged:

```bash
# Check a specific resource
terraform state show aws_instance.example | grep tags

# List all resources with tags
terraform state list | xargs -I {} terraform state show {} | grep -A 5 tags
```

### Custom Tag Configuration

If you need different tag values, configure the module:

```hcl
module "chatops" {
  source = "./terraform-aws-chatops"
  
  # ... other configuration ...
  
  resource_tag_key   = "MyCustomTag"
  resource_tag_value = "managed"
}
```

**Important**: When using custom tags, ensure all resources use the same tag key and value.

### Troubleshooting

**Issue**: `UnauthorizedOperation` when trying to destroy resources  
**Solution**: Verify resources have the `ChatOpsManaged = "true"` tag

**Issue**: Resources destroyed but not tagged  
**Solution**: Add tags to existing resources and run `terraform apply` to update tags

**Issue**: Module resources not tagged  
**Solution**: Ensure modules pass through tags or tag resources directly

## Terraform Backend Configuration

ChatOps uses AWS Secrets Manager to store Terraform backend configuration. The project registry stores multiple projects, each with their own backend configuration.

### Project Registry Structure

The project registry is stored in `chatops/project-registry` secret with the following structure:

```json
{
  "projects": {
    "project1": {
      "backend_bucket": "tf-state-bucket",
      "backend_key": "project1/terraform.tfstate",
      "region": "us-east-1",
      "workspace": "default",
      "enabled": true
    },
    "project2": {
      "backend_bucket": "tf-state-bucket",
      "backend_key": "project2/terraform.tfstate",
      "region": "eu-west-1",
      "workspace": "prod",
      "enabled": true
    }
  }
}
```

### Key Fields

- **backend_bucket** (required): S3 bucket name for Terraform state
- **backend_key** (required): S3 key path for state file (without `env:/<workspace>/` prefix)
- **region** (required): AWS region for S3 bucket
- **workspace** (optional): Terraform workspace name, defaults to `"default"` if missing
- **enabled** (optional): Whether project is enabled, defaults to `true`

### Workspace Handling

- Workspace is stored separately from the backend key in the project registry
- Terraform automatically adds `env:/<workspace>/` prefix when workspace is selected
- Default workspace is `"default"` (Terraform standard) if not specified
- Backend key should NOT include `env:/<workspace>/` prefix

### Example: Adding a Project

```bash
# Add project to registry
aws secretsmanager get-secret-value \
  --secret-id chatops/project-registry \
  --query SecretString --output text | \
  jq --arg name "my-project" \
     --arg bucket "tf-state-bucket" \
     --arg key "my-project/terraform.tfstate" \
     --arg region "us-east-1" \
     --arg workspace "default" \
     '.projects[$name] = {
       backend_bucket: $bucket,
       backend_key: $key,
       region: $region,
       workspace: $workspace,
       enabled: true
     }' | \
  aws secretsmanager put-secret-value \
    --secret-id chatops/project-registry \
    --secret-string file:///dev/stdin
```

For more details, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#terraform-backend-configuration).

## Security Features

- **GitHub OIDC**: No long-lived credentials, federated authentication
- **Secrets Manager**: Centralized secret storage with automatic rotation support
- **Least Privilege IAM**: Minimal permissions for each component
- **API Gateway Security**: Rate limiting, throttling, optional API keys
- **CloudWatch Logging**: Comprehensive audit trails
- **X-Ray Tracing**: Request tracing for debugging

## License

MIT

## Contributing

Contributions welcome! Please open an issue or PR.

## Support

For issues and questions, please use GitHub Issues.

