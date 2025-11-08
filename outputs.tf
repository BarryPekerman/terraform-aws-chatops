# Core Secrets Outputs
output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.core_secrets.secret_arn
}

output "secrets_manager_name" {
  description = "Name of the Secrets Manager secret"
  value       = module.core_secrets.secret_name
}

# Webhook Handler Outputs
output "webhook_url" {
  description = "Webhook API Gateway URL"
  value       = module.core_webhook.api_gateway_url
}

output "webhook_api_key" {
  description = "Webhook API key (if enabled)"
  value       = module.core_webhook.api_key_value
  sensitive   = true
}

output "webhook_function_arn" {
  description = "ARN of the webhook handler Lambda"
  value       = module.core_webhook.lambda_function_arn
}

# GitHub OIDC Outputs
output "github_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = module.github.github_role_arn
}

output "github_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = module.github.github_role_name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.github.oidc_provider_arn
}

# Telegram Bot Outputs
output "telegram_bot_function_arn" {
  description = "ARN of the Telegram bot Lambda"
  value       = module.telegram.bot_function_arn
}

output "telegram_bot_function_name" {
  description = "Name of the Telegram bot Lambda"
  value       = module.telegram.bot_function_name
}

# AI Output Processor Outputs
output "ai_processor_url" {
  description = "AI output processor API Gateway URL"
  value       = module.ai_processor.processor_api_url
}

output "ai_processor_function_arn" {
  description = "ARN of the AI output processor Lambda"
  value       = module.ai_processor.processor_function_arn
}

output "ai_processor_function_name" {
  description = "Name of the AI output processor Lambda"
  value       = module.ai_processor.processor_function_name
}

# Project Registry Outputs
output "project_registry_secret_arn" {
  description = "ARN of the project registry secret"
  value       = module.core_secrets.project_registry_secret_arn
}

output "project_registry_secret_name" {
  description = "Name of the project registry secret"
  value       = module.core_secrets.project_registry_secret_name
}

# Monitoring Outputs
output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_arn
}


