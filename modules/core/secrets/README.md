# Secrets Module

## Purpose

This module creates and manages the AWS Secrets Manager secret for ChatOps credentials. It provisions:

- **Secrets Manager Secret**: Centralized secret storage for all ChatOps credentials
- **Secret Version**: Initial secret value with all required credentials

## Responsibilities

- Store GitHub personal access token
- Store Telegram bot token
- Store API Gateway key
- Provide secret ARN for use by other modules
- Protect secrets from accidental overwrites (lifecycle protection)

## Usage

```hcl
module "secrets" {
  source = "./modules/core/secrets"

  name_prefix        = "my-chatops"
  github_token       = var.github_token
  telegram_bot_token = var.telegram_bot_token
  api_gateway_key    = var.api_gateway_key

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name_prefix` | Prefix for secret name | `string` | - | yes |
| `github_token` | GitHub personal access token | `string` | - | yes (sensitive) |
| `telegram_bot_token` | Telegram bot token | `string` | - | yes (sensitive) |
| `api_gateway_key` | API Gateway key for authentication | `string` | `""` | no (sensitive) |
| `callback_url` | Webhook callback URL for GitHub Actions workflows | `string` | `""` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `secret_arn` | ARN of the Secrets Manager secret |
| `secret_name` | Name of the Secrets Manager secret |
| `secret_id` | ID of the Secrets Manager secret |
| `terraform_backend_secret_arn` | ARN of the secret (same as secret_arn, for Terraform backend) |

## Secret Structure

The secret is stored as a JSON object with the following structure:

```json
{
  "github_token": "ghp_...",
  "telegram_bot_token": "123456:ABC...",
  "api_gateway_key": "...",
  "callback_url": "https://xxxxx.execute-api.region.amazonaws.com/prod/webhook"
}
```

**Note**: The `callback_url` field is automatically populated after the webhook API Gateway is created. It is used by GitHub Actions workflows to send callback responses back to the webhook handler.

## Dependencies

### None
This module has no dependencies on other modules. It should be created first as other modules depend on its output.

## Important Considerations

1. **Lifecycle Protection**: The secret uses `ignore_changes = [secret_string]` to prevent accidental overwrites from Terraform
2. **Secret Updates**: To update secrets after creation, use AWS Console, AWS CLI, or Secrets Manager API directly
3. **Callback URL**: The `callback_url` field is automatically updated by a `null_resource` in the root module after the webhook API Gateway is created. This ensures GitHub Actions workflows always use the correct callback URL without manual updates
4. **Secret Rotation**: Automatic rotation is not configured in this module. See [Advanced Configuration](../../../docs/ADVANCED.md) for rotation setup
5. **Secret Naming**: Secret name format: `${name_prefix}/secrets`
6. **Terraform Backend**: The `terraform_backend_secret_arn` output is provided for convenience and references the same secret
7. **Sensitive Variables**: All token variables are marked as `sensitive` to prevent accidental exposure in logs

## Example: With API Gateway Key

```hcl
module "secrets" {
  source = "./modules/core/secrets"

  name_prefix        = "chatops-prod"
  github_token       = var.github_token
  telegram_bot_token = var.telegram_bot_token
  api_gateway_key    = random_password.api_key.result

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Related Modules

- **[Webhook Handler Module](../webhook-handler/)** - Uses secret ARN to access credentials
- **[Telegram Bot Module](../../chat/telegram/)** - Uses secret ARN to access Telegram token
- **[GitHub Module](../../cicd/github/)** - Uses secret ARN to access GitHub token
- **[AI Output Processor Module](../ai-output-processor/)** - Uses secret ARN to access credentials

