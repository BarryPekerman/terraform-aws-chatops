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

  environment {
    variables = merge(
      {
        ENABLE_AI_PROCESSING = tostring(var.enable_ai_processing)
        MAX_MESSAGE_LENGTH   = tostring(var.max_message_length)
        AI_THRESHOLD         = tostring(var.ai_threshold)
        AI_MODEL_ID          = var.ai_model_id
      },
      var.additional_env_vars
    )
  }

  depends_on = [aws_cloudwatch_log_group.output_processor_logs]

  tags = var.tags
}


