output "secret_arn" {
  description = "ARN of the secrets manager secret"
  value       = aws_secretsmanager_secret.chatops_secrets.arn
}

output "secret_name" {
  description = "Name of the secrets manager secret"
  value       = aws_secretsmanager_secret.chatops_secrets.name
}

output "secret_id" {
  description = "ID of the secrets manager secret"
  value       = aws_secretsmanager_secret.chatops_secrets.id
}


