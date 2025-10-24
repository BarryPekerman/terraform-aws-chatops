output "bot_function_arn" {
  description = "ARN of the Telegram bot Lambda function"
  value       = aws_lambda_function.telegram_bot.arn
}

output "bot_function_name" {
  description = "Name of the Telegram bot Lambda function"
  value       = aws_lambda_function.telegram_bot.function_name
}

output "bot_role_arn" {
  description = "ARN of the bot IAM role"
  value       = aws_iam_role.bot_role.arn
}


