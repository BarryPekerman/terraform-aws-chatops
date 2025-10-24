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

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = var.tags
}


