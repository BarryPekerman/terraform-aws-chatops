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

# KMS key for Lambda environment variable encryption
resource "aws_kms_key" "lambda_env_key" {
  description             = "KMS key for ${var.function_name} environment variables"
  deletion_window_in_days = 7

  tags = var.tags
}

resource "aws_kms_alias" "lambda_env_key_alias" {
  name          = "alias/${var.function_name}-env"
  target_key_id = aws_kms_key.lambda_env_key.key_id
}

# SQS Dead Letter Queue for failed Lambda invocations
resource "aws_sqs_queue" "lambda_dlq" {
  name = "${var.function_name}-dlq"

  tags = var.tags
}

# CloudWatch log group for bot
resource "aws_cloudwatch_log_group" "bot_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda function for Telegram bot
resource "aws_lambda_function" "telegram_bot" {
  function_name    = var.function_name
  handler          = "bot.lambda_handler"
  runtime          = "python3.11"
  filename         = var.lambda_zip_path
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null

  role = aws_iam_role.bot_role.arn

  kms_key_arn = aws_kms_key.lambda_env_key.arn

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


