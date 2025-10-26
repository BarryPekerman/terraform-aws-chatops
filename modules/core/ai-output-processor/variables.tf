variable "function_name" {
  description = "Name of the output processor Lambda function"
  type        = string
}

variable "api_gateway_name" {
  description = "Name of the API Gateway for output processor"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package"
  type        = string
}

variable "enable_ai_processing" {
  description = "Enable AI processing for long outputs"
  type        = bool
  default     = true
}

variable "max_message_length" {
  description = "Maximum message length before AI summarization"
  type        = number
  default     = 3500
}

variable "ai_threshold" {
  description = "Threshold for triggering AI processing"
  type        = number
  default     = 3500
}

variable "ai_model_id" {
  description = "AWS Bedrock model ID for AI processing"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "ai_max_tokens" {
  description = "Maximum tokens for AI model response (cost control)"
  type        = number
  default     = 1000
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

variable "api_key_required" {
  description = "Whether API key is required"
  type        = bool
  default     = true
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


