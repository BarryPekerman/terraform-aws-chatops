# AI Output Processor Module

## Purpose

This module creates the AI output processor Lambda function for summarizing long workflow outputs using AWS Bedrock. It provisions:

- **Lambda Function**: Processes long outputs and generates AI summaries
- **API Gateway** (optional): REST API endpoint for processing outputs
- **SQS Dead Letter Queue**: Handles failed Lambda invocations
- **IAM Role and Policies**: Least-privilege permissions for Bedrock access
- **CloudWatch Log Group**: Centralized logging for Lambda function

## Responsibilities

- Receive long workflow outputs from webhook handler
- Summarize outputs using AWS Bedrock (Amazon Titan)
- Return concise summaries for Telegram
- Handle errors gracefully with DLQ
- Control costs via token limits

## Usage

```hcl
module "ai_processor" {
  source = "./modules/core/ai-output-processor"

  function_name       = "chatops-ai-processor"
  api_gateway_name    = "chatops-ai-api"
  lambda_zip_path     = "../lambda/ai-processor.zip"
  enable_ai_processing = true
  ai_model_id         = "amazon.titan-text-lite-v1"
  ai_max_tokens       = 1000
  secrets_manager_arn = module.secrets.secret_arn

  # Optional: Use direct Lambda invoke (recommended) or API Gateway
  use_api_gateway = false

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `function_name` | Name of the Lambda function | `string` | - | yes |
| `api_gateway_name` | Name of the API Gateway | `string` | - | yes |
| `lambda_zip_path` | Path to Lambda deployment ZIP file | `string` | - | yes |
| `enable_ai_processing` | Enable AI processing | `bool` | `true` | no |
| `max_message_length` | Maximum message length before AI | `number` | `3500` | no |
| `ai_threshold` | Threshold for triggering AI processing | `number` | `3500` | no |
| `ai_model_id` | AWS Bedrock model ID | `string` | `"amazon.titan-text-lite-v1"` | no |
| `ai_max_tokens` | Maximum tokens for AI response | `number` | `1000` | no |
| `stage_name` | API Gateway stage name | `string` | `"prod"` | no |
| `log_retention_days` | CloudWatch log retention (days) | `number` | `7` | no |
| `api_key_required` | Require API key for API Gateway | `bool` | `true` | no |
| `use_api_gateway` | Expose via API Gateway (false = direct invoke) | `bool` | `false` | no |
| `enable_security_alarms` | Enable CloudWatch security alarms | `bool` | `false` | no |
| `lambda_timeout` | Lambda timeout (seconds, 3-900) | `number` | `30` | no |
| `lambda_memory_size` | Lambda memory (MB, 128-10240, multiple of 64) | `number` | `256` | no |
| `dlq_message_retention_seconds` | DLQ message retention (seconds) | `number` | `1209600` | no |
| `dlq_visibility_timeout_seconds` | DLQ visibility timeout (seconds) | `number` | `30` | no |
| `secrets_manager_arn` | ARN of Secrets Manager secret | `string` | `null` | no |
| `additional_env_vars` | Additional environment variables | `map(string)` | `{}` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `processor_function_arn` | ARN of the Lambda function |
| `processor_function_name` | Name of the Lambda function |
| `processor_api_url` | URL of API Gateway (if enabled) |
| `processor_lambda_invoke_arn` | ARN for direct Lambda invocation |
| `processor_api_key` | API key value (if enabled, sensitive) |

## Dependencies

### Optional
- **Secrets Manager Secret**: If `secrets_manager_arn` provided, enables access to credentials
- **Webhook Handler**: Invokes this Lambda for long outputs (via `AI_PROCESSOR_FUNCTION_ARN`)

## Important Considerations

1. **AWS Bedrock Access**: Requires Bedrock service access and appropriate IAM permissions
2. **Cost Control**: `ai_max_tokens` limits response size to control costs
3. **API Gateway vs Direct Invoke**: 
   - Direct invoke (default): Lower cost, faster, for internal use
   - API Gateway: For external access, adds cost and latency
4. **Model Selection**: Default is `amazon.titan-text-lite-v1` (cost-effective). Can use other Bedrock models
5. **Threshold**: Messages longer than `ai_threshold` characters trigger AI processing
6. **Lambda ZIP File**: The `lambda_zip_path` must point to an existing ZIP file
7. **Bedrock Region**: Bedrock model access is region-specific; ensure model is available in deployment region
8. **DLQ**: Failed Lambda invocations are sent to SQS DLQ for manual inspection

## Example: Direct Lambda Invoke (Recommended)

```hcl
module "ai_processor" {
  source = "./modules/core/ai-output-processor"

  function_name       = "chatops-ai-processor"
  api_gateway_name    = "chatops-ai-api"
  lambda_zip_path     = "../lambda/ai-processor.zip"
  secrets_manager_arn = module.secrets.secret_arn
  ai_model_id         = "amazon.titan-text-lite-v1"
  ai_max_tokens       = 1000

  # Use direct Lambda invoke (recommended for internal use)
  use_api_gateway = false

  tags = {
    Environment = "production"
  }
}
```

## Example: Via API Gateway

```hcl
module "ai_processor" {
  source = "./modules/core/ai-output-processor"

  function_name       = "chatops-ai-processor"
  api_gateway_name    = "chatops-ai-api"
  lambda_zip_path     = "../lambda/ai-processor.zip"
  secrets_manager_arn = module.secrets.secret_arn

  # Expose via API Gateway
  use_api_gateway    = true
  api_key_required   = true

  tags = {
    Environment = "production"
  }
}
```

## Related Modules

- **[Secrets Module](../secrets/)** - Provides secret ARN for credentials
- **[Webhook Handler Module](../webhook-handler/)** - Invokes this Lambda for long outputs
- **[Security Module](../security/)** - Provides security alarms (optional)

