# Basic Example - ChatOps with Telegram + GitHub (No AI)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "chatops" {
  source = "../../"

  name_prefix        = var.name_prefix
  github_owner       = var.github_owner
  github_repo        = var.github_repo
  github_branch      = var.github_branch
  github_token       = var.github_token
  telegram_bot_token = var.telegram_bot_token
  authorized_chat_id = var.authorized_chat_id
  s3_bucket_arn      = var.s3_bucket_arn

  webhook_lambda_zip_path  = var.webhook_lambda_zip_path
  telegram_lambda_zip_path = var.telegram_lambda_zip_path

  max_message_length = var.max_message_length
  log_retention_days = var.log_retention_days

  tags = {
    Environment = "production"
    Project     = "chatops"
    ManagedBy   = "terraform"
  }
}


