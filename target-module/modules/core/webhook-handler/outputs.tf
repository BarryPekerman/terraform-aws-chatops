output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.webhook_handler.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.webhook_handler.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.webhook_api.id
}

output "api_gateway_url" {
  description = "URL of the webhook endpoint"
  value       = "${aws_api_gateway_stage.webhook_stage.invoke_url}/webhook"
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.webhook_stage.stage_name
}

output "api_key_value" {
  description = "API key value (if enabled)"
  value       = var.api_key_required ? aws_api_gateway_api_key.webhook_api_key[0].value : null
  sensitive   = true
}

output "api_key_id" {
  description = "API key ID (if enabled)"
  value       = var.api_key_required ? aws_api_gateway_api_key.webhook_api_key[0].id : null
}


