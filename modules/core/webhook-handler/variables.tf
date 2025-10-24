variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "authorized_chat_id" {
  description = "Authorized Telegram chat ID"
  type        = string
}

variable "secrets_manager_arn" {
  description = "ARN of the secrets manager secret"
  type        = string
}

variable "max_message_length" {
  description = "Maximum length of messages (will be truncated if longer)"
  type        = number
  default     = 3500
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 365
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "API Gateway rate limit (requests per second)"
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

variable "api_key_required" {
  description = "Whether API key is required for webhook endpoint"
  type        = bool
  default     = false
}

variable "additional_env_vars" {
  description = "Additional environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


