# IAM role for bot Lambda
resource "aws_iam_role" "bot_role" {
  name        = "${var.function_name}-role"
  description = "IAM role for ${var.function_name} Lambda function to access Secrets Manager and send messages to DLQ"

  assume_role_policy = file("${path.module}/policies/assume-role-policy.json")

  tags = var.tags
}

# IAM policy for bot Lambda
resource "aws_iam_policy" "bot_policy" {
  name        = "${var.function_name}-policy"
  description = "IAM policy for ${var.function_name} Lambda function to access Secrets Manager and send messages to DLQ"

  policy = templatefile("${path.module}/policies/lambda-policy.json.tpl", {
    region              = data.aws_region.current.id
    account_id          = data.aws_caller_identity.current.account_id
    secrets_manager_arn = var.secrets_manager_arn
    dlq_arn             = var.enable_dlq ? aws_sqs_queue.lambda_dlq[0].arn : null
  })

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "bot_policy" {
  role       = aws_iam_role.bot_role.name
  policy_arn = aws_iam_policy.bot_policy.arn
}

