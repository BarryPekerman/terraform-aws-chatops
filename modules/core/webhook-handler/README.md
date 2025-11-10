# Webhook Handler Module

## Purpose

This module creates the core webhook handler infrastructure for processing Telegram webhook requests and triggering GitHub Actions workflows. It provisions:

- **Lambda Function**: Processes incoming Telegram webhook requests
- **API Gateway**: REST API endpoint for receiving webhooks
- **SQS Dead Letter Queue**: Handles failed Lambda invocations
- **IAM Role and Policies**: Least-privilege permissions for Lambda execution
- **CloudWatch Log Group**: Centralized logging for Lambda function
- **Security Module** (optional): Security alarms and enhanced monitoring

## Responsibilities

- Receive and validate Telegram webhook requests
- Authenticate requests using Telegram bot token
- Authorize requests based on chat ID
- Trigger GitHub Actions workflows via GitHub API
- Optionally invoke AI processor for output summarization
- Handle errors gracefully with DLQ

## Usage

```hcl
module "webhook_handler" {
  source = "./modules/core/webhook-handler"

  function_name       = "my-chatops-webhook-handler"
  api_gateway_name    = "my-chatops-webhook-api"
  lambda_zip_path     = "../lambda/webhook-handler.zip"
  github_owner        = "my-org"
  github_repo         = "my-repo"
  authorized_chat_id  = "123456789"
  secrets_manager_arn = module.secrets.secret_arn

  # Optional: Security alarms
  enable_security_alarms = true

  # Optional: Lambda configuration
  lambda_timeout     = 30
  lambda_memory_size = 128

  tags = {
    Environment = "production"
  }
}
```

## Lambda ZIP File Requirements

**Important:** The Lambda ZIP file must exist before running `terraform apply`. There is no fallback behavior - if the ZIP file doesn't exist, Terraform will fail.

**Current Behavior:**
- `lambda_zip_path` must point to an existing ZIP file
- `fileexists()` check only affects `source_code_hash` (sets to null if file doesn't exist)
- Terraform will fail if the ZIP file doesn't exist when creating the Lambda function
- No conditional creation - Lambda function is always created if module is used

**Best Practices:**
- Build Lambda ZIP files before running Terraform
- Use CI/CD to build and package Lambda functions
- Store ZIP files in a consistent location (e.g., `../lambda/` directory)
- Document ZIP file build process in your project README

**Example Build Process:**
```bash
# Build Lambda function
cd lambda/webhook-handler
pip install -r requirements.txt -t .
zip -r ../../webhook-handler.zip .

# Then run Terraform
cd ../../terraform
terraform apply
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `function_name` | Name of the Lambda function | `string` | - | yes |
| `api_gateway_name` | Name of the API Gateway | `string` | - | yes |
| `lambda_zip_path` | Path to Lambda deployment ZIP file | `string` | - | yes |
| `github_owner` | GitHub repository owner/organization | `string` | - | yes |
| `github_repo` | GitHub repository name | `string` | - | yes |
| `authorized_chat_id` | Authorized Telegram chat ID | `string` | - | yes |
| `secrets_manager_arn` | ARN of Secrets Manager secret | `string` | - | yes |
| `max_message_length` | Maximum message length (characters) | `number` | `3500` | no |
| `stage_name` | API Gateway stage name | `string` | `"prod"` | no |
| `log_retention_days` | CloudWatch log retention (days) | `number` | `7` | no |
| `enable_xray_tracing` | Enable X-Ray tracing | `bool` | `true` | no |
| `rate_limit` | API Gateway rate limit (req/sec) | `number` | `100` | no |
| `burst_limit` | API Gateway burst limit | `number` | `200` | no |
| `quota_limit` | API Gateway quota limit | `number` | `10000` | no |
| `quota_period` | API Gateway quota period | `string` | `"DAY"` | no |
| `api_key_required` | Require API key for webhook endpoint | `bool` | `false` | no |
| `enable_security_alarms` | Enable CloudWatch security alarms | `bool` | `false` | no |
| `lambda_timeout` | Lambda timeout (seconds, 3-900) | `number` | `30` | no |
| `lambda_memory_size` | Lambda memory (MB, 128-10240, multiple of 64) | `number` | `128` | no |
| `dlq_message_retention_seconds` | DLQ message retention (seconds) | `number` | `1209600` | no |
| `dlq_visibility_timeout_seconds` | DLQ visibility timeout (seconds) | `number` | `30` | no |
| `high_request_rate_threshold` | High request rate alarm threshold | `number` | `50` | no |
| `high_error_rate_threshold` | High error rate alarm threshold | `number` | `10` | no |
| `lambda_errors_threshold` | Lambda errors alarm threshold | `number` | `5` | no |
| `lambda_duration_threshold` | Lambda duration alarm threshold (ms) | `number` | `25000` | no |
| `large_payloads_threshold` | Large payloads alarm threshold (ms) | `number` | `5000` | no |
| `api_throttling_threshold` | API throttling alarm threshold | `number` | `5` | no |
| `ai_processor_function_arn` | AI processor Lambda ARN (optional) | `string` | `null` | no |
| `ai_threshold` | AI processing threshold (characters) | `number` | `5000` | no |
| `additional_env_vars` | Additional environment variables | `map(string)` | `{}` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_function_arn` | ARN of the Lambda function |
| `lambda_function_name` | Name of the Lambda function |
| `lambda_role_arn` | ARN of the Lambda IAM role |
| `api_gateway_id` | ID of the API Gateway |
| `api_gateway_url` | URL of the webhook endpoint |
| `api_gateway_stage_name` | Name of the API Gateway stage |
| `api_key_value` | API key value (if enabled, sensitive) |
| `api_key_id` | API key ID (if enabled) |

## Dependencies

### Required
- **Secrets Manager Secret**: Must exist with `github_token`, `telegram_bot_token`, and `api_gateway_key`
- **CloudWatch Log Group**: Created by this module

### Optional
- **AI Processor Lambda**: If `ai_processor_function_arn` is provided, enables AI processing for long outputs

## Important Considerations

1. **Lambda ZIP File**: The `lambda_zip_path` must point to an existing ZIP file containing the Lambda deployment package
2. **Secrets Manager**: The secret must contain valid credentials; this module does not create the secret
3. **API Gateway URL**: The webhook URL is provided in the output and must be configured in Telegram bot settings
4. **Rate Limiting**: Default rate limits are 100 req/sec with burst of 200; adjust based on expected traffic
5. **Security Alarms**: When enabled, creates CloudWatch alarms for DDoS detection, error monitoring, and anomaly detection
6. **DLQ**: Failed Lambda invocations are sent to SQS DLQ for manual inspection and retry
7. **CORS**: Disabled by default (not needed for Telegram webhooks). Enable only if web dashboard integration is planned

## Retry Behavior and Error Handling

**Important:** Retry logic is implemented in the Lambda code (separate repository), not in Terraform. This module provides the infrastructure (DLQ, IAM permissions) for retry handling.

### Recommended Retry Patterns

The Lambda code should implement the following retry patterns:

#### GitHub API Calls
- Use exponential backoff for GitHub API calls
- Retry on rate limit errors (429) with appropriate delay
- Retry on transient errors (5XX) with exponential backoff
- Don't retry on client errors (4XX) except for rate limits
- Maximum retry attempts: 3-5 retries

#### Dead Letter Queue (DLQ)
- Failed invocations are sent to DLQ after Lambda retries are exhausted
- DLQ retention: 4 days (AWS default)
- DLQ encryption: AWS-managed encryption (SQS-managed SSE)
- Monitor DLQ for failed invocations
- Process DLQ messages manually or with a separate Lambda function

#### Secrets Manager Failures
- No graceful degradation if Secrets Manager is unavailable
- Lambda will fail if Secrets Manager is unavailable
- Implement retry logic for Secrets Manager API calls
- Use exponential backoff for Secrets Manager failures

### Lambda Code Repository

The actual retry logic implementation should be in the Lambda code repository. This module only provides the infrastructure for retry handling.

**Reference Implementation:**
- Lambda code repository: [chatops-state-manager](https://github.com/BarryPekerman/chatops-state-manager)
- See Lambda code for actual retry implementation

For more details, see [Development Documentation](../../../docs/DEVELOPMENT.md#retry-behavior-and-error-handling).

## Example: With Security Alarms

```hcl
module "webhook_handler" {
  source = "./modules/core/webhook-handler"

  function_name       = "chatops-webhook-handler"
  api_gateway_name    = "chatops-webhook-api"
  lambda_zip_path     = "../lambda/webhook-handler.zip"
  github_owner        = "my-org"
  github_repo         = "my-repo"
  authorized_chat_id  = "123456789"
  secrets_manager_arn = module.secrets.secret_arn

  # Enable security monitoring
  enable_security_alarms = true
  
  # Customize alarm thresholds
  high_request_rate_threshold = 100  # Higher threshold for production
  lambda_errors_threshold     = 10   # More tolerant for expected errors

  tags = {
    Environment = "production"
  }
}
```

## Related Modules

- **[Secrets Module](../secrets/)** - Creates and manages Secrets Manager secret
- **[Security Module](../security/)** - Provides security alarms and enhanced logging
- **[GitHub Module](../../cicd/github/)** - Provides GitHub OIDC and IAM configuration

