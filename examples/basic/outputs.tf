output "webhook_url" {
  description = "Webhook API Gateway URL"
  value       = module.chatops.webhook_url
}

output "github_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.chatops.github_role_arn
}

output "telegram_bot_function_name" {
  description = "Telegram bot Lambda function name"
  value       = module.chatops.telegram_bot_function_name
}

output "secrets_manager_name" {
  description = "Secrets Manager secret name"
  value       = module.chatops.secrets_manager_name
}


