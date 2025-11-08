# Telegram Bot Module

## Purpose

This module creates the Telegram bot Lambda function for sending messages to Telegram chats. It provisions:

- **Lambda Function**: Sends messages to Telegram via Telegram Bot API
- **SQS Dead Letter Queue**: Handles failed Lambda invocations
- **IAM Role and Policies**: Least-privilege permissions for Telegram API access
- **CloudWatch Log Group**: Centralized logging for Lambda function

## Responsibilities

- Send messages to Telegram chats
- Authenticate with Telegram Bot API using bot token
- Authorize message sending based on chat ID
- Handle errors gracefully with DLQ
- Support message formatting and truncation

## Usage

```hcl
module "telegram_bot" {
  source = "./modules/chat/telegram"

  function_name       = "chatops-telegram-bot"
  lambda_zip_path     = "../lambda/telegram-bot.zip"
  api_gateway_url     = module.webhook_handler.api_gateway_url
  authorized_chat_id  = "123456789"
  secrets_manager_arn = module.secrets.secret_arn

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `function_name` | Name of the Lambda function | `string` | - | yes |
| `lambda_zip_path` | Path to Lambda deployment ZIP file | `string` | - | yes |
| `api_gateway_url` | URL of webhook API Gateway | `string` | - | yes |
| `authorized_chat_id` | Authorized Telegram chat ID | `string` | - | yes |
| `secrets_manager_arn` | ARN of Secrets Manager secret | `string` | - | yes |
| `log_retention_days` | CloudWatch log retention (days) | `number` | `7` | no |
| `enable_security_alarms` | Enable CloudWatch security alarms | `bool` | `false` | no |
| `lambda_timeout` | Lambda timeout (seconds, 3-900) | `number` | `30` | no |
| `lambda_memory_size` | Lambda memory (MB, 128-10240, multiple of 64) | `number` | `128` | no |
| `dlq_message_retention_seconds` | DLQ message retention (seconds) | `number` | `1209600` | no |
| `dlq_visibility_timeout_seconds` | DLQ visibility timeout (seconds) | `number` | `30` | no |
| `additional_env_vars` | Additional environment variables | `map(string)` | `{}` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bot_function_arn` | ARN of the Lambda function |
| `bot_function_name` | Name of the Lambda function |
| `bot_role_arn` | ARN of the IAM role |

## Dependencies

### Required
- **Webhook Handler API Gateway**: The `api_gateway_url` must be from webhook handler module
- **Secrets Manager Secret**: Must contain `telegram_bot_token`

## Important Considerations

1. **Lambda ZIP File**: The `lambda_zip_path` must point to an existing ZIP file containing the Lambda deployment package
2. **Telegram Bot Token**: Must be stored in Secrets Manager secret at `telegram_bot_token`
3. **API Gateway URL**: Must be the webhook API Gateway URL from webhook-handler module output
4. **Chat ID Authorization**: Only messages to `authorized_chat_id` are processed
5. **Message Formatting**: Lambda code handles message formatting and truncation
6. **Telegram API Rate Limits**: Bot respects Telegram API rate limits (20 messages/minute per chat)
7. **DLQ**: Failed Lambda invocations are sent to SQS DLQ for manual inspection and retry
8. **Security**: Bot token is retrieved from Secrets Manager at runtime

## Example: With Custom Configuration

```hcl
module "telegram_bot" {
  source = "./modules/chat/telegram"

  function_name       = "chatops-telegram-bot"
  lambda_zip_path     = "../lambda/telegram-bot.zip"
  api_gateway_url     = module.webhook_handler.api_gateway_url
  authorized_chat_id  = "123456789"
  secrets_manager_arn = module.secrets.secret_arn

  # Custom Lambda configuration
  lambda_timeout     = 60
  lambda_memory_size = 256

  # Custom DLQ configuration
  dlq_message_retention_seconds = 2592000  # 30 days

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Related Modules

- **[Secrets Module](../../core/secrets/)** - Provides secret ARN for Telegram bot token
- **[Webhook Handler Module](../../core/webhook-handler/)** - Provides API Gateway URL
- **[Security Module](../../core/security/)** - Provides security alarms (optional)

