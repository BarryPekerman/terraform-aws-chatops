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

output "project_registry_secret_arn" {
  description = "ARN of the project registry secret"
  value       = aws_secretsmanager_secret.project_registry.arn
}

output "project_registry_secret_name" {
  description = "Name of the project registry secret"
  value       = aws_secretsmanager_secret.project_registry.name
}


