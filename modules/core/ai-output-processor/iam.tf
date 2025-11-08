# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM role for output processor Lambda
resource "aws_iam_role" "output_processor_role" {
  name        = "${var.function_name}-role"
  description = "IAM role for ${var.function_name} Lambda function to access AWS Bedrock, Secrets Manager, and send messages to DLQ"

  assume_role_policy = file("${path.module}/policies/assume-role-policy.json")

  tags = var.tags
}

# IAM policy for output processor Lambda
resource "aws_iam_policy" "output_processor_policy" {
  name        = "${var.function_name}-policy"
  description = "IAM policy for ${var.function_name} Lambda function to access AWS Bedrock, Secrets Manager, and send messages to DLQ"

  policy = templatefile("${path.module}/policies/lambda-policy.json.tpl", {
    ai_model_id         = var.ai_model_id
    secrets_manager_arn = var.secrets_manager_arn != null && var.secrets_manager_arn != "" ? var.secrets_manager_arn : ""
    dlq_arn             = aws_sqs_queue.lambda_dlq.arn
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "output_processor_policy" {
  role       = aws_iam_role.output_processor_role.name
  policy_arn = aws_iam_policy.output_processor_policy.arn
}


