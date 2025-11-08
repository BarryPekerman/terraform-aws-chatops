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

# SQS Dead Letter Queue for failed Lambda invocations
resource "aws_sqs_queue" "lambda_dlq" {
  name                    = "${var.function_name}-dlq"
  sqs_managed_sse_enabled = true # AWS-managed encryption (free, secure)

  # AWS defaults: 4-day retention, 30-second visibility timeout
  # No explicit configuration needed

  tags = var.tags
}

# Note: SQS queues don't support description fields

# CloudWatch log group for bot
# checkov:skip=CKV_AWS_158:Using default CloudWatch encryption per ADR-0006 (no KMS keys)
# trivy:ignore:AVD-AWS-0017 Using default CloudWatch encryption per ADR-0006 (no KMS keys)
resource "aws_cloudwatch_log_group" "bot_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Note: CloudWatch log groups don't support description fields

# Lambda function for Telegram bot
# checkov:skip=CKV_AWS_117:VPC not required - Lambda only accesses public AWS services (Secrets Manager, SQS, CloudWatch) and public APIs (Telegram Bot API)
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

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  timeout     = 30
  memory_size = 128

  depends_on = [aws_cloudwatch_log_group.bot_logs]

  tags = var.tags
}


