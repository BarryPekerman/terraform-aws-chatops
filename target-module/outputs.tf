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


