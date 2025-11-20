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

variable "project_registry_secret_arn" {
  description = "ARN of the project registry secret"
  type        = string
  default     = null
}

variable "ai_processor_function_arn" {
  description = "ARN of the AI processor Lambda function (optional)"
  type        = string
  default     = null
}

variable "ai_threshold" {
  description = "Output length threshold for AI processing (default: 5000 characters)"
  type        = number
  default     = 5000
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
  description = "CloudWatch log retention in days (default: 7 for cost optimization)"
  type        = number
  default     = 7
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for Lambda environment variables and CloudWatch logs"
  type        = bool
  default     = true
}

variable "enable_dlq" {
  description = "Enable Dead Letter Queue for Lambda function"
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

variable "enable_security_alarms" {
  description = "Enable CloudWatch security alarms and enhanced logging"
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for Lambda function (prevents runaway costs)"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


