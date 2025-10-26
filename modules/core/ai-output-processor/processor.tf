# AI Output Processor Lambda Module (Optional)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

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
  name                       = "${var.function_name}-dlq"
  sqs_managed_sse_enabled    = true
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300

  tags = var.tags
}

# CloudWatch log group for output processor
resource "aws_cloudwatch_log_group" "output_processor_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Output Processor Lambda Function
resource "aws_lambda_function" "output_processor" {
  filename         = var.lambda_zip_path
  function_name    = var.function_name
  role             = aws_iam_role.output_processor_role.arn
  handler          = "processor.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null

  kms_key_arn = aws_kms_key.lambda_env_key.arn

  environment {
    variables = merge(
      {
        ENABLE_AI_PROCESSING = tostring(var.enable_ai_processing)
        MAX_MESSAGE_LENGTH   = tostring(var.max_message_length)
        AI_THRESHOLD         = tostring(var.ai_threshold)
        AI_MODEL_ID          = var.ai_model_id
        AI_MAX_TOKENS        = tostring(var.ai_max_tokens)
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

  depends_on = [aws_cloudwatch_log_group.output_processor_logs]

  tags = var.tags
}


