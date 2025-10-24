output "processor_function_arn" {
  description = "ARN of the output processor Lambda function"
  value       = aws_lambda_function.output_processor.arn
}

output "processor_function_name" {
  description = "Name of the output processor Lambda function"
  value       = aws_lambda_function.output_processor.function_name
}

output "processor_api_url" {
  description = "URL of the output processor API"
  value       = "${aws_api_gateway_stage.output_processor_stage.invoke_url}/process"
}

output "processor_api_key" {
  description = "API key for output processor (if enabled)"
  value       = var.api_key_required ? aws_api_gateway_api_key.output_processor_key[0].value : null
  sensitive   = true
}


