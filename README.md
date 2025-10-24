# terraform-aws-chatops

Terraform module for deploying ChatOps infrastructure on AWS. Manage your infrastructure through Telegram with secure GitHub Actions integration.

## Quick Start

```hcl
module "chatops" {
  source = "github.com/BarryPekerman/terraform-aws-chatops//target-module"

  name_prefix        = "my-chatops"
  github_owner       = "my-org"
  github_repo        = "my-repo"
  github_token       = var.github_token
  telegram_bot_token = var.telegram_bot_token
  authorized_chat_id = var.authorized_chat_id
  s3_bucket_arn      = "arn:aws:s3:::my-terraform-state"

  # Path to Lambda ZIP files
  webhook_lambda_zip_path  = "./lambda_function.zip"
  telegram_lambda_zip_path = "./telegram-bot.zip"
}
```

## Features

- 🤖 **Telegram Integration** - Send commands via Telegram bot
- 🔐 **Secure by Default** - GitHub OIDC, AWS Secrets Manager, least-privilege IAM
- 🧩 **Modular Design** - Use only the components you need
- 🤖 **Optional AI** - AWS Bedrock integration for output summarization
- 📊 **Production Ready** - CloudWatch logging, API rate limiting

## Architecture

The module creates:
- **2 Lambda functions**: Webhook handler + Telegram bot
- **1 API Gateway**: Webhook endpoint with CORS and rate limiting
- **1 Secrets Manager secret**: Centralized credential storage
- **1 GitHub OIDC provider**: Federated authentication
- **3 IAM roles + policies**: Least-privilege access control
- **CloudWatch log groups**: Comprehensive logging

Optional AI module adds AI output processor with AWS Bedrock access.

## Requirements

- **Terraform**: >= 1.0
- **AWS Provider**: ~> 6.0
- **Lambda Code**: You must provide Lambda ZIP files (see [chatops-state-manager](https://github.com/BarryPekerman/chatops-state-manager) for reference implementation)

## Module Structure

```
target-module/
├── modules/
│   ├── core/              # Secrets, webhook handler
│   ├── cicd/              # GitHub OIDC + IAM
│   └── chat/              # Telegram bot
├── modules-optional/
│   └── ai-output-processor/  # Optional AI processing
└── examples/
    ├── basic/             # Simple setup
    └── with-ai/           # With AI processor
```

## Examples

### Basic (Telegram + GitHub)

See [examples/basic](target-module/examples/basic/) for complete example.

### With AI Processing

```hcl
module "chatops" {
  source = "github.com/BarryPekerman/terraform-aws-chatops//target-module"
  # ... same as basic
}

module "ai_processor" {
  source = "github.com/BarryPekerman/terraform-aws-chatops//target-module/modules-optional/ai-output-processor"

  function_name        = "my-chatops-ai-processor"
  api_gateway_name     = "my-chatops-ai-api"
  lambda_zip_path      = "./output_processor.zip"
  enable_ai_processing = true
  ai_model_id         = "anthropic.claude-3-haiku-20240307-v1:0"
}
```

## Security

- ✅ GitHub OIDC (no long-lived AWS credentials)
- ✅ AWS Secrets Manager for credentials
- ✅ Least-privilege IAM policies
- ✅ API Gateway rate limiting
- ✅ CloudWatch audit logging
- ✅ No hardcoded secrets

## Testing

```bash
cd target-module
terraform fmt -recursive
terraform init -backend=false
terraform validate

# Test examples
cd examples/basic
terraform init -backend=false
terraform plan
```

## Documentation

- **[Module README](target-module/README.md)** - Detailed module documentation
- **[Basic Example](target-module/examples/basic/)** - Simple setup
- **[AI Example](target-module/examples/with-ai/)** - With AI processor

## License

MIT License - see [LICENSE](LICENSE) file

## Contributing

Contributions welcome! Please test changes locally and update documentation.

---

**Note**: This module provides infrastructure only. Lambda application code must be provided separately. See [chatops-state-manager](https://github.com/BarryPekerman/chatops-state-manager) for a complete reference implementation.
