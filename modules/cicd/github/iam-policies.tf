# Tagged Resource Destroy Policy - Refactored
# This file contains the policy statements for tagged resource destruction
# Organized by AWS service for better maintainability

locals {
  # List of AWS service resource types and their destroy actions
  # This structure makes it easier to maintain and extend
  tagged_destroy_config = [
    {
      service = "EC2/VPC"
      sid     = "Ec2VpcDestroyTagged"
      actions = [
        "ec2:TerminateInstances",
        "ec2:DeleteSecurityGroup",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DeleteSubnet",
        "ec2:DisassociateRouteTable",
        "ec2:DeleteRoute",
        "ec2:ReplaceRoute",
        "ec2:DeleteRouteTable",
        "ec2:DetachInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteNetworkAcl",
        "ec2:DeleteNetworkAclEntry",
        "ec2:DeleteVpc",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteImage",
        "ec2:DeleteKeyPair"
      ]
    },
    {
      service = "S3"
      sid     = "S3DestroyTagged"
      actions = [
        "s3:DeleteBucket",
        "s3:DeleteBucketPolicy",
        "s3:DeleteBucketTagging",
        "s3:DeleteBucketVersioning",
        "s3:DeleteBucketWebsite",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ]
    },
    {
      service = "RDS"
      sid     = "RDSDestroyTagged"
      actions = [
        "rds:DeleteDBInstance",
        "rds:DeleteDBCluster",
        "rds:DeleteDBSnapshot",
        "rds:DeleteDBClusterSnapshot",
        "rds:DeleteDBSubnetGroup",
        "rds:DeleteDBParameterGroup",
        "rds:DeleteDBClusterParameterGroup"
      ]
    },
    {
      service = "DynamoDB"
      sid     = "DynamoDBDestroyTagged"
      actions = [
        "dynamodb:DeleteTable",
        "dynamodb:DeleteBackup",
        "dynamodb:DeleteGlobalTable"
      ]
    },
    {
      service = "Lambda"
      sid     = "LambdaDestroyTagged"
      actions = [
        "lambda:DeleteFunction",
        "lambda:DeleteFunctionEventInvokeConfig",
        "lambda:DeleteLayerVersion",
        "lambda:DeleteAlias"
      ]
    },
    {
      service = "API Gateway"
      sid     = "ApiGatewayDestroyTagged"
      actions = [
        "apigateway:DELETE",
        "apigateway:DeleteRestApi",
        "apigateway:DeleteStage",
        "apigateway:DeleteResource"
      ]
    },
    {
      service = "ECS"
      sid     = "ECSDestroyTagged"
      actions = [
        "ecs:DeleteService",
        "ecs:DeleteCluster",
        "ecs:StopTask",
        "ecs:DeleteTaskDefinition"
      ]
    },
    {
      service = "Auto Scaling"
      sid     = "AutoScalingDestroyTagged"
      actions = [
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DeleteLaunchConfiguration",
        "autoscaling:DeleteLaunchTemplate",
        "autoscaling:DeleteScalingPolicy"
      ]
    },
    {
      service = "CloudFormation"
      sid     = "CloudFormationDestroyTagged"
      actions = [
        "cloudformation:DeleteStack",
        "cloudformation:DeleteStackSet",
        "cloudformation:DeleteChangeSet"
      ]
    },
    {
      service = "ELB/ALB"
      sid     = "ELBDestroyTagged"
      actions = [
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteRule"
      ]
    },
    {
      service = "CloudWatch"
      sid     = "CloudWatchDestroyTagged"
      actions = [
        "cloudwatch:DeleteAlarms",
        "logs:DeleteLogGroup",
        "logs:DeleteLogStream",
        "cloudwatch:DeleteDashboard"
      ]
    },
    {
      service = "SNS"
      sid     = "SNSDestroyTagged"
      actions = [
        "sns:DeleteTopic",
        "sns:RemovePermission"
      ]
    },
    {
      service = "SQS"
      sid     = "SQSDestroyTagged"
      actions = [
        "sqs:DeleteQueue",
        "sqs:RemovePermission"
      ]
    },
    {
      service = "IAM"
      sid     = "IAMDestroyTagged"
      actions = [
        "iam:DeleteRole",
        "iam:DeletePolicy",
        "iam:DeleteInstanceProfile",
        "iam:DetachRolePolicy",
        "iam:RemoveRoleFromInstanceProfile"
      ]
    }
  ]

  # Helper: Tag condition used by all statements
  tag_condition = {
    StringEquals = {
      "aws:ResourceTag/${var.resource_tag_key}" = var.resource_tag_value
    }
  }

  # Generate policy statements from configuration
  tagged_destroy_statements = [
    for config in local.tagged_destroy_config : {
      Sid       = config.sid
      Effect    = "Allow"
      Action    = config.actions
      Resource  = "*"
      Condition = local.tag_condition
    }
  ]
}

# Tagged Resource Destroy permissions - All AWS service resource types with tag-based conditions
resource "aws_iam_policy" "github_tagged_resource_destroy" {
  name        = "${var.role_name}-tagged-resource-destroy"
  description = "Permissions to destroy tagged resources across all AWS services. Only affects resources tagged with ${var.resource_tag_key}=${var.resource_tag_value}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.tagged_destroy_statements
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "github_tagged_resource_destroy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_tagged_resource_destroy.arn
}

