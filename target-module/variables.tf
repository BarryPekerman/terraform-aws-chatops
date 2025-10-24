variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch for OIDC authentication"
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
  description = "Path to webhook handler Lambda ZIP file"
  type        = string
}

variable "telegram_lambda_zip_path" {
  description = "Path to Telegram bot Lambda ZIP file"
  type        = string
}

variable "max_message_length" {
  description = "Maximum message length (simple truncation)"
  type        = number
  default     = 3500
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for API Gateway"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "API Gateway rate limit (requests/second)"
  type        = number
  default     = 100
}

variable "burst_limit" {
  description = "API Gateway burst limit"
  type        = number
  default     = 200
}

variable "quota_limit" {
  description = "API Gateway quota limit"
  type        = number
  default     = 10000
}

variable "quota_period" {
  description = "API Gateway quota period"
  type        = string
  default     = "DAY"
}

variable "webhook_api_key_required" {
  description = "Whether webhook API requires API key"
  type        = bool
  default     = false
}

variable "webhook_additional_env_vars" {
  description = "Additional environment variables for webhook Lambda"
  type        = map(string)
  default     = {}
}

variable "telegram_additional_env_vars" {
  description = "Additional environment variables for Telegram bot Lambda"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "chatops"
  }
}


