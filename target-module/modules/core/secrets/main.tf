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

  lifecycle {
    ignore_changes = [secret_string]
  }
}


