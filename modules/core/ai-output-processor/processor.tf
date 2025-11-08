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

# SQS Dead Letter Queue for failed Lambda invocations
resource "aws_sqs_queue" "lambda_dlq" {
  name                    = "${var.function_name}-dlq"
  sqs_managed_sse_enabled = true # AWS-managed encryption (free, secure)

  # AWS defaults: 4-day retention, 30-second visibility timeout
  # No explicit configuration needed

  tags = var.tags
}

# Note: SQS queues don't support description fields

# CloudWatch log group for output processor
resource "aws_cloudwatch_log_group" "output_processor_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Note: CloudWatch log groups don't support description fields

# Output Processor Lambda Function
resource "aws_lambda_function" "output_processor" {
  filename         = var.lambda_zip_path
  function_name    = var.function_name
  description      = "Lambda function for processing and summarizing long Terraform outputs using AWS Bedrock AI"
  role             = aws_iam_role.output_processor_role.arn
  handler          = "processor.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null

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


