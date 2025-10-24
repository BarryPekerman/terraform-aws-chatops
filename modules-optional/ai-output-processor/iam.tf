# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM role for output processor Lambda
resource "aws_iam_role" "output_processor_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for output processor Lambda
resource "aws_iam_policy" "output_processor_policy" {
  name = "${var.function_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "bedrock:modelId" = var.ai_model_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "output_processor_policy" {
  role       = aws_iam_role.output_processor_role.name
  policy_arn = aws_iam_policy.output_processor_policy.arn
}


