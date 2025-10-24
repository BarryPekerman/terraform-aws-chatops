# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = file("${path.module}/policies/assume-role-policy.json")

  tags = var.tags
}

# IAM policy for Lambda to write logs and access secrets
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}-policy"
  description = "Policy for ${var.function_name} Lambda function"

  policy = templatefile("${path.module}/policies/lambda-policy.json.tpl", {
    region              = data.aws_region.current.id
    account_id          = data.aws_caller_identity.current.account_id
    secrets_manager_arn = var.secrets_manager_arn
    kms_key_arn         = aws_kms_key.lambda_env_key.arn
    dlq_arn             = aws_sqs_queue.lambda_dlq.arn
  })

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

