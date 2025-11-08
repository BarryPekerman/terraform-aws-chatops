variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "chatops"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^(ghp_|gho_|ghu_|ghs_|ghr_)", var.github_token))
    error_message = "GitHub token must start with ghp_, gho_, ghu_, ghs_, or ghr_."
  }
}

variable "telegram_bot_token" {
  description = "Telegram bot token"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[0-9]+:[A-Za-z0-9_-]+$", var.telegram_bot_token))
    error_message = "Telegram bot token must be in format: <bot_id>:<token> (e.g., 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11)."
  }
}

variable "authorized_chat_id" {
  description = "Authorized Telegram chat ID"
  type        = string
  validation {
    condition     = can(regex("^-?[0-9]+$", var.authorized_chat_id))
    error_message = "Chat ID must be a numeric string (can be negative for groups)."
  }
}

variable "s3_bucket_arn" {
  description = "ARN of S3 bucket for Terraform state"
  type        = string
}

variable "webhook_lambda_zip_path" {
  description = "Path to webhook Lambda ZIP"
  type        = string
  default     = "lambda_function.zip"
}

variable "telegram_lambda_zip_path" {
  description = "Path to Telegram bot Lambda ZIP"
  type        = string
  default     = "telegram-bot.zip"
}

variable "ai_processor_lambda_zip_path" {
  description = "Path to AI processor Lambda ZIP"
  type        = string
  default     = "output_processor.zip"
}

variable "max_message_length" {
  description = "Maximum message length for base webhook handler"
  type        = number
  default     = 3500
  validation {
    condition     = var.max_message_length > 0 && var.max_message_length <= 4096
    error_message = "Max message length must be between 1 and 4096 characters (Telegram limit)."
  }
}

variable "enable_ai_processing" {
  description = "Enable AI processing for long outputs"
  type        = bool
  default     = true
}

variable "ai_max_message_length" {
  description = "Maximum message length for AI processor"
  type        = number
  default     = 3500
}

variable "ai_threshold" {
  description = "Threshold for triggering AI processing"
  type        = number
  default     = 3500
  validation {
    condition     = var.ai_threshold > 0 && var.ai_threshold <= 100000
    error_message = "AI threshold must be between 1 and 100000 characters."
  }
}

variable "ai_model_id" {
  description = "AWS Bedrock model ID for AI processing"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "Log retention must be between 1 and 3653 days."
  }
}

variable "enable_security_alarms" {
  description = "Enable CloudWatch security alarms and enhanced logging"
  type        = bool
  default     = false
}


