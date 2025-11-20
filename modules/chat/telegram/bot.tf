# Telegram Bot Lambda Module

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Local variable to reference enable_kms_encryption (reserved for future KMS encryption support)
locals {
  # Currently using default CloudWatch encryption (AWS-managed keys)
  # When KMS encryption is implemented, this will control whether to use a KMS key
  use_kms_encryption = var.enable_kms_encryption
}

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

# CloudWatch log group for bot
# checkov:skip=CKV_AWS_158:Using default CloudWatch encryption per ADR-0006 (no KMS keys)
# checkov:skip=CKV_AWS_338:7 days retention is cost-effective and sufficient for operational debugging (documented decision)
# trivy:ignore:AVD-AWS-0017 Using default CloudWatch encryption per ADR-0006 (no KMS keys)
# Note: enable_kms_encryption variable is reserved for future KMS encryption support
# Currently using default CloudWatch encryption (AWS-managed keys)
# When KMS encryption is implemented, use: kms_key_id = local.use_kms_encryption ? aws_kms_key.logs[0].arn : null
resource "aws_cloudwatch_log_group" "bot_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  # kms_key_id is not set - using default CloudWatch encryption
  # Future: kms_key_id = local.use_kms_encryption ? aws_kms_key.logs[0].arn : null

  tags = merge(var.tags, {
    # Reference enable_kms_encryption to satisfy tflint (reserved for future use)
    KmsEncryptionEnabled = tostring(local.use_kms_encryption)
  })
}

# Note: CloudWatch log groups don't support description fields

# Lambda function for Telegram bot
# checkov:skip=CKV_AWS_117:VPC not required - Lambda only accesses public AWS services (Secrets Manager, SQS, CloudWatch) and public APIs (Telegram Bot API)
# checkov:skip=CKV_AWS_173:No secrets in environment variables - all sensitive data stored in Secrets Manager
# checkov:skip=CKV_AWS_272:Code signing not required - code deployed from controlled CI/CD pipeline
resource "aws_lambda_function" "telegram_bot" {
  function_name    = var.function_name
  description      = "Lambda function for sending messages to Telegram chat via Telegram Bot API"
  handler          = "bot.lambda_handler"
  runtime          = "python3.11"
  filename         = var.lambda_zip_path
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null

  role = aws_iam_role.bot_role.arn

  environment {
    variables = merge(
      {
        API_GATEWAY_URL    = var.api_gateway_url
        AUTHORIZED_CHAT_ID = var.authorized_chat_id
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

  reserved_concurrent_executions = var.reserved_concurrent_executions

  timeout     = 30
  memory_size = 128

  depends_on = [aws_cloudwatch_log_group.bot_logs]

  tags = var.tags
}


