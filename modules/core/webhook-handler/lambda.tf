# SQS Dead Letter Queue for failed Lambda invocations
resource "aws_sqs_queue" "lambda_dlq" {
  count                   = var.enable_dlq ? 1 : 0
  name                    = "${var.function_name}-dlq"
  sqs_managed_sse_enabled = true # AWS-managed encryption (free, secure)

  # AWS defaults: 4-day retention, 30-second visibility timeout
  # No explicit configuration needed

  tags = var.tags
}

# Note: SQS queues don't support description fields

# CloudWatch Log Group for Lambda function
# checkov:skip=CKV_AWS_158:Using default CloudWatch encryption per ADR-0006 (no KMS keys)
# checkov:skip=CKV_AWS_338:7 days retention is cost-effective and sufficient for operational debugging (documented decision)
# trivy:ignore:AVD-AWS-0017 Using default CloudWatch encryption per ADR-0006 (no KMS keys)
# Note: enable_kms_encryption variable is reserved for future KMS encryption support
# Currently using default CloudWatch encryption (AWS-managed keys)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  # kms_key_id = var.enable_kms_encryption ? aws_kms_key.logs[0].arn : null  # Future: implement KMS encryption

  tags = var.tags
}

# Note: CloudWatch log groups don't support description fields

# Lambda function for webhook handler (ZIP package)
# checkov:skip=CKV_AWS_117:VPC not required - Lambda only accesses public AWS services (Secrets Manager, SQS, CloudWatch) and public APIs (GitHub API, Telegram API)
# checkov:skip=CKV_AWS_173:No secrets in environment variables - all sensitive data stored in Secrets Manager
# checkov:skip=CKV_AWS_272:Code signing not required - code deployed from controlled CI/CD pipeline
resource "aws_lambda_function" "webhook_handler" {
  function_name    = var.function_name
  description      = "Lambda function for processing Telegram webhook requests and triggering GitHub Actions workflows"
  role             = aws_iam_role.lambda_role.arn
  handler          = "webhook_handler.lambda_handler"
  runtime          = "python3.11"
  filename         = var.lambda_zip_path
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null

  reserved_concurrent_executions = var.reserved_concurrent_executions

  timeout     = 30
  memory_size = 128

  environment {
    variables = merge(
      {
        GITHUB_OWNER                = var.github_owner
        GITHUB_REPO                 = var.github_repo
        AUTHORIZED_CHAT_ID          = var.authorized_chat_id
        MAX_MESSAGE_LENGTH          = var.max_message_length
        PROJECT_REGISTRY_SECRET_ARN = var.project_registry_secret_arn != null ? var.project_registry_secret_arn : ""
        AI_PROCESSOR_FUNCTION_ARN   = var.ai_processor_function_arn != null && var.ai_processor_function_arn != "" ? var.ai_processor_function_arn : ""
        AI_THRESHOLD                = var.ai_threshold
      },
      var.additional_env_vars
    )
  }

  dynamic "dead_letter_config" {
    for_each = var.enable_dlq ? [1] : []
    content {
      target_arn = aws_sqs_queue.lambda_dlq[0].arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = var.tags
}


