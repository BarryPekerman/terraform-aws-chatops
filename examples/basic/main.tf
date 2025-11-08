# Basic Example - ChatOps with Telegram + GitHub (No AI)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Backend Configuration (for production use)
  # Uncomment and configure for remote state management with state locking:
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "chatops/basic/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"  # Required for state locking
  #   encrypt        = true                    # Enable encryption at rest
  # }
  #
  # Prerequisites:
  # 1. Create S3 bucket for state storage (with versioning enabled)
  # 2. Create DynamoDB table for state locking (partition key: LockID, type: String)
  # 3. Ensure IAM permissions for S3 and DynamoDB access
  #
  # For local development, leave this commented out (uses local state)
}

provider "aws" {
  region = var.aws_region

  # Skip credential validation for plan-only runs (CI/CD)
  # In production, remove these settings and use proper AWS credentials
  skip_credentials_validation = true
  skip_metadata_api_check     = true
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

  webhook_lambda_zip_path      = var.webhook_lambda_zip_path
  telegram_lambda_zip_path     = var.telegram_lambda_zip_path
  ai_processor_lambda_zip_path = var.ai_processor_lambda_zip_path

  max_message_length     = var.max_message_length
  log_retention_days     = var.log_retention_days
  enable_security_alarms = var.enable_security_alarms

  tags = {
    Environment = "production"
    Project     = "chatops"
    ManagedBy   = "terraform"
  }
}


