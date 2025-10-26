# Variables for ChatOps with Security Example

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "chatops-secure"
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
}

variable "telegram_bot_token" {
  description = "Telegram bot token"
  type        = string
  sensitive   = true
}

variable "authorized_chat_id" {
  description = "Authorized Telegram chat ID"
  type        = string
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
  description = "Maximum message length"
  type        = number
  default     = 3500
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
