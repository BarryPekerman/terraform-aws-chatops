# Terraform Permissions Policy
# Provides comprehensive Terraform permissions for GitHub Actions
# - Full access (read/write/delete) for tagged resources (ChatOpsManaged=true)
# - Read-only access for all resources (needed for Terraform plan operations)

locals {
  # List of AWS services that support tag-based conditions
  terraform_services = [
    {
      service = "EC2"
      actions = ["ec2:*"]
    },
    {
      service = "S3"
      actions = ["s3:*"]
    },
    {
      service = "RDS"
      actions = ["rds:*"]
    },
    {
      service = "DynamoDB"
      actions = ["dynamodb:*"]
    },
    {
      service = "Lambda"
      actions = ["lambda:*"]
    },
    {
      service = "API Gateway"
      actions = ["apigateway:*"]
    },
    {
      service = "CloudWatch Logs"
      actions = ["logs:*"]
    },
    {
      service = "SNS"
      actions = ["sns:*"]
    },
    {
      service = "SQS"
      actions = ["sqs:*"]
    },
    {
      service = "ECS"
      actions = ["ecs:*"]
    },
    {
      service = "Auto Scaling"
      actions = ["autoscaling:*"]
    },
    {
      service = "ELB"
      actions = ["elasticloadbalancing:*"]
    },
    {
      service = "Route53"
      actions = ["route53:*"]
    },
    {
      service = "CloudFront"
      actions = ["cloudfront:*"]
    },
    {
      service = "ECR"
      actions = ["ecr:*"]
    },
    {
      service = "EKS"
      actions = ["eks:*"]
    },
    {
      service = "Secrets Manager"
      actions = ["secretsmanager:*"]
    }
  ]

  # Tag condition for tagged resources (defined here to avoid duplication with iam-policies.tf)
  terraform_tag_condition = {
    StringEquals = {
      "aws:ResourceTag/${var.resource_tag_key}" = var.resource_tag_value
    }
  }

  # Generate full access statements for tagged resources
  tagged_full_access_statements = [
    for service in local.terraform_services : {
      Sid       = "${replace(service.service, " ", "")}FullAccessTagged"
      Effect    = "Allow"
      Action    = service.actions
      Resource  = "*"
      Condition = local.terraform_tag_condition
    }
  ]

  # VPC-specific permissions (tagged resources)
  vpc_tagged_statements = [
    {
      Sid    = "VPCFullAccessTagged"
      Effect = "Allow"
      Action = [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:DescribeVpcs",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        "ec2:DescribeSubnets",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DescribeSecurityGroups"
      ]
      Resource  = "*"
      Condition = local.terraform_tag_condition
    }
  ]

  # Read-only permissions for tagged resources
  # Note: AWS IAM cannot check "any tag exists", so we allow read operations on all resources
  # In practice, this is used for Terraform plan operations on tagged resources
  # The condition checks for resources with the ChatOpsManaged tag, but Terraform needs
  # to read all resources to understand the current state during plan operations
  read_only_statements = [
    {
      Sid    = "ReadOnlyForPlan"
      Effect = "Allow"
      Action = [
        "ec2:Describe*",
        "ec2:Get*",
        "ec2:List*",
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "s3:GetBucketTagging",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "rds:Describe*",
        "rds:List*",
        "dynamodb:List*",
        "dynamodb:Describe*",
        "lambda:List*",
        "lambda:Get*",
        "apigateway:GET",
        "logs:Describe*",
        "logs:List*",
        "sns:List*",
        "sns:Get*",
        "sqs:List*",
        "sqs:Get*",
        "ecs:List*",
        "ecs:Describe*",
        "autoscaling:Describe*",
        "elasticloadbalancing:Describe*",
        "route53:List*",
        "route53:Get*",
        "cloudfront:List*",
        "cloudfront:Get*",
        "ecr:Describe*",
        "ecr:List*",
        "eks:List*",
        "eks:Describe*",
        "secretsmanager:ListSecrets",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "*"
      # Note: Read operations are allowed on all resources because:
      # 1. AWS IAM cannot check "any tag exists" condition
      # 2. Terraform needs to read resources to understand current state during plan
      # 3. Write/Delete operations are restricted to tagged resources only
      # In practice, this is used for reading tagged resources during Terraform operations
    }
  ]
}

# Terraform Permissions Policy
resource "aws_iam_policy" "github_terraform_permissions" {
  name        = "${var.role_name}-terraform-permissions"
  description = "Comprehensive Terraform permissions for GitHub Actions. Full access for tagged resources, read-only for all resources (Terraform plan)."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      local.tagged_full_access_statements,
      local.vpc_tagged_statements,
      local.read_only_statements
    )
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_terraform_permissions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_terraform_permissions.arn
}

