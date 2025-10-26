# Outputs for Security Module

output "security_alerts_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = var.enable_security_alarms ? aws_sns_topic.security_alerts[0].arn : null
}

output "security_logs_arn" {
  description = "ARN of the security logs CloudWatch log group"
  value       = var.enable_security_alarms ? aws_cloudwatch_log_group.security_logs[0].arn : null
}

output "enhanced_api_logs_arn" {
  description = "ARN of the enhanced API logs CloudWatch log group"
  value       = var.enable_security_alarms ? aws_cloudwatch_log_group.enhanced_api_logs[0].arn : null
}
