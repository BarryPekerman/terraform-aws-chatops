variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
}

variable "webhook_function_name" {
  description = "Name of the webhook handler Lambda function"
  type        = string
}

variable "telegram_function_name" {
  description = "Name of the Telegram bot Lambda function"
  type        = string
}

variable "ai_processor_function_name" {
  description = "Name of the AI processor Lambda function (optional)"
  type        = string
  default     = ""
}

variable "webhook_api_name" {
  description = "Name of the webhook API Gateway"
  type        = string
}

variable "webhook_stage_name" {
  description = "Stage name of the webhook API Gateway"
  type        = string
  default     = "prod"
}

variable "ai_api_name" {
  description = "Name of the AI processor API Gateway (optional)"
  type        = string
  default     = ""
}

variable "ai_stage_name" {
  description = "Stage name of the AI processor API Gateway"
  type        = string
  default     = "prod"
}

variable "webhook_log_group" {
  description = "CloudWatch log group name for webhook handler"
  type        = string
}

variable "telegram_log_group" {
  description = "CloudWatch log group name for Telegram bot"
  type        = string
}

variable "ai_processor_log_group" {
  description = "CloudWatch log group name for AI processor (optional)"
  type        = string
  default     = ""
}

variable "enable_security_alarms" {
  description = "Enable security alarm widgets on dashboard"
  type        = bool
  default     = false
}

variable "high_request_rate_threshold" {
  description = "High request rate threshold for dashboard annotation"
  type        = number
  default     = 50
}

variable "high_error_rate_threshold" {
  description = "High error rate threshold for dashboard annotation"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
