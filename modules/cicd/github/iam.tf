# IAM Role and Policies for GitHub Actions

data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  description        = "ChatOps Terraform role for GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role_policy.json

  tags = var.tags
}

# Core permissions policy
resource "aws_iam_policy" "github_permissions_policy" {
  name        = "${var.role_name}-permissions"
  description = "Core permissions for ChatOps GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerBackendRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = compact([
          var.secrets_manager_arn,
          var.project_registry_secret_arn
        ])
      },
      {
        Sid    = "TfStateBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arn
      },
      {
        Sid    = "TfStateObjectRW"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_permissions_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_permissions_policy.arn
}

# Note: EC2 read-only and destroy permissions are now part of the terraform-permissions policy
# See iam-terraform-permissions.tf for comprehensive Terraform permissions


