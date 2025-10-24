# Advanced Example - ChatOps with Telegram + GitHub + AI Output Processor

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

# Base ChatOps module (no AI)
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

# Optional AI Output Processor module
module "ai_processor" {
  source = "../../modules-optional/ai-output-processor"

  function_name        = "${var.name_prefix}-ai-processor"
  api_gateway_name     = "${var.name_prefix}-ai-processor-api"
  lambda_zip_path      = var.ai_processor_lambda_zip_path
  enable_ai_processing = var.enable_ai_processing
  max_message_length   = var.ai_max_message_length
  ai_threshold         = var.ai_threshold
  ai_model_id          = var.ai_model_id
  log_retention_days   = var.log_retention_days
  api_key_required     = true

  tags = {
    Environment = "production"
    Project     = "chatops"
    Component   = "ai-processor"
    ManagedBy   = "terraform"
  }
}


