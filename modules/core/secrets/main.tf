# Core Secrets Module - Centralized secret management

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# These are long-lived credentials that are updated manually when needed. Automatic rotation would require a Lambda function
# and doesn't provide value for static credentials. See ADR-0006 and module README for details.
# checkov:skip=CKV_AWS_149:Using AWS-managed encryption per ADR-0006 (cost optimization, AWS-managed encryption is secure)
# checkov:skip=CKV_AWS_193:Automatic rotation not required for static credentials (GitHub token, Telegram bot token, API key)
# checkov:skip=CKV2_AWS_57:Automatic rotation not required for static credentials (GitHub token, Telegram bot token, API key)
resource "aws_secretsmanager_secret" "chatops_secrets" {
  name        = "${var.name_prefix}/secrets"
  description = "ChatOps secrets and configuration"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "chatops_secrets" {
  secret_id = aws_secretsmanager_secret.chatops_secrets.id
  secret_string = jsonencode({
    github_token       = var.github_token
    telegram_bot_token = var.telegram_bot_token
    api_gateway_key    = var.api_gateway_key
  })
}

# Project Registry - Always Enabled
# Stores multiple Terraform projects in a single registry secret
# checkov:skip=CKV_AWS_149:Using AWS-managed encryption per ADR-0006 (cost optimization, AWS-managed encryption is secure)
# checkov:skip=CKV_AWS_193:Automatic rotation not required for project registry (configuration data, not credentials)
# checkov:skip=CKV2_AWS_57:Automatic rotation not required for project registry (configuration data, not credentials)
resource "aws_secretsmanager_secret" "project_registry" {
  name        = "${var.name_prefix}/project-registry"
  description = "ChatOps project registry - stores all Terraform project configurations"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "project_registry" {
  secret_id = aws_secretsmanager_secret.project_registry.id
  secret_string = jsonencode({
    projects = {}
  })
}


