# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM role for output processor Lambda
resource "aws_iam_role" "output_processor_role" {
  name = "${var.function_name}-role"

  assume_role_policy = file("${path.module}/policies/assume-role-policy.json")

  tags = var.tags
}

# IAM policy for output processor Lambda
resource "aws_iam_policy" "output_processor_policy" {
  name = "${var.function_name}-policy"

  policy = templatefile("${path.module}/policies/lambda-policy.json.tpl", {
    ai_model_id = var.ai_model_id
    kms_key_arn = aws_kms_key.lambda_env_key.arn
    dlq_arn     = aws_sqs_queue.lambda_dlq.arn
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "output_processor_policy" {
  role       = aws_iam_role.output_processor_role.name
  policy_arn = aws_iam_policy.output_processor_policy.arn
}


