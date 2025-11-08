# ChatOps Terraform Module v1.0

A production-ready Terraform module for building ChatOps workflows on AWS. This module enables you to manage infrastructure through Telegram with secure GitHub Actions integration.

## Architecture
 
```
┌─────────────────────────────────────────────────────────────────┐
│                         ChatOps v1.0                            │
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
- **Core AI Processing**: Built-in AWS Bedrock integration for output summarization
- **Production Ready**: CloudWatch logging, X-Ray tracing, API throttling
- **Modular Architecture**: Core modules (secrets, webhook, AI) + CI/CD + chat integration

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

### Telegram (v1.0)

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

