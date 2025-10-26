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

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda function for webhook handler (ZIP package)
resource "aws_lambda_function" "webhook_handler" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "webhook_handler.lambda_handler"
  runtime          = "python3.11"
  filename         = var.lambda_zip_path
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null

  timeout     = 30
  memory_size = 128

  kms_key_arn = aws_kms_key.lambda_env_key.arn

  environment {
    variables = merge(
      {
        GITHUB_OWNER       = var.github_owner
        GITHUB_REPO        = var.github_repo
        AUTHORIZED_CHAT_ID = var.authorized_chat_id
        MAX_MESSAGE_LENGTH = var.max_message_length
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

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = var.tags
}


