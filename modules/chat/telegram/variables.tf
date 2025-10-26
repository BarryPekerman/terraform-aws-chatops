variable "function_name" {
  description = "Name of the Telegram bot Lambda function"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package"
  type        = string
}

variable "api_gateway_url" {
  description = "URL of the webhook API Gateway"
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

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 365
}

variable "additional_env_vars" {
  description = "Additional environment variables for the bot Lambda"
  type        = map(string)
  default     = {}
}

variable "enable_security_alarms" {
  description = "Enable CloudWatch security alarms and enhanced logging"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


