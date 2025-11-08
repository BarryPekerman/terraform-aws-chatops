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
  validation {
    condition     = can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_bucket_arn)) || can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9-]*[a-z0-9]/.*$", var.s3_bucket_arn))
    error_message = "S3 bucket ARN must be a valid ARN format: arn:aws:s3:::bucket-name or arn:aws:s3:::bucket-name/path."
  }
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
  validation {
    condition     = var.max_message_length > 0 && var.max_message_length <= 4096
    error_message = "Max message length must be between 1 and 4096 characters (Telegram limit)."
  }
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (default: 7 for cost optimization)"
  type        = number
  default     = 7
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "Log retention must be between 1 and 3653 days."
  }
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
  validation {
    condition     = var.rate_limit > 0 && var.rate_limit <= 10000
    error_message = "Rate limit must be between 1 and 10000 requests per second."
  }
}

variable "burst_limit" {
  description = "API Gateway burst limit"
  type        = number
  default     = 200
  validation {
    condition     = var.burst_limit > 0 && var.burst_limit <= 5000
    error_message = "Burst limit must be between 1 and 5000."
  }
}

variable "quota_limit" {
  description = "API Gateway quota limit"
  type        = number
  default     = 10000
  validation {
    condition     = var.quota_limit > 0
    error_message = "Quota limit must be greater than 0."
  }
}

variable "quota_period" {
  description = "API Gateway quota period"
  type        = string
  default     = "DAY"
  validation {
    condition     = contains(["DAY", "WEEK", "MONTH"], var.quota_period)
    error_message = "Quota period must be DAY, WEEK, or MONTH."
  }
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

# AI Output Processor Configuration (Lambda always exists)
variable "ai_processor_lambda_zip_path" {
  description = "Path to AI output processor Lambda ZIP file"
  type        = string
}

variable "enable_ai_processing" {
  description = "Enable AI processing via AWS Bedrock (requires Bedrock permissions)"
  type        = bool
  default     = false
}

variable "ai_model_id" {
  description = "AWS Bedrock model ID for AI processing"
  type        = string
  default     = "amazon.titan-text-express-v1"
}

variable "ai_threshold" {
  description = "Minimum message length (characters) to trigger AI processing"
  type        = number
  default     = 1000
  validation {
    condition     = var.ai_threshold > 0 && var.ai_threshold <= 100000
    error_message = "AI threshold must be between 1 and 100000 characters."
  }
}

variable "ai_max_tokens" {
  description = "Maximum tokens for AI model response (cost control)"
  type        = number
  default     = 1000
  validation {
    condition     = var.ai_max_tokens > 0 && var.ai_max_tokens <= 8192
    error_message = "AI max tokens must be between 1 and 8192 (typical model limit)."
  }
}

variable "ai_processor_additional_env_vars" {
  description = "Additional environment variables for AI processor Lambda"
  type        = map(string)
  default     = {}
}

variable "enable_security_alarms" {
  description = "Enable CloudWatch security alarms and enhanced logging for all Lambda functions"
  type        = bool
  default     = false
}

variable "high_request_rate_threshold" {
  description = "High request rate threshold for dashboard annotation"
  type        = number
  default     = 50
  validation {
    condition     = var.high_request_rate_threshold > 0
    error_message = "High request rate threshold must be greater than 0."
  }
}

variable "high_error_rate_threshold" {
  description = "High error rate threshold for dashboard annotation"
  type        = number
  default     = 10
  validation {
    condition     = var.high_error_rate_threshold > 0
    error_message = "High error rate threshold must be greater than 0."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "chatops"
  }
}

variable "resource_tag_key" {
  description = "Tag key for ChatOps-managed resources. Resources must have this tag to be managed by ChatOps."
  type        = string
  default     = "ChatOpsManaged"
}

variable "resource_tag_value" {
  description = "Tag value for ChatOps-managed resources. Resources must have this tag value to be managed by ChatOps."
  type        = string
  default     = "true"
}


