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

  environment {
    variables = merge(
      {
        API_GATEWAY_URL    = var.api_gateway_url
        AUTHORIZED_CHAT_ID = var.authorized_chat_id
      },
      var.additional_env_vars
    )
  }

  timeout     = 30
  memory_size = 128

  depends_on = [aws_cloudwatch_log_group.bot_logs]

  tags = var.tags
}


