# API Gateway for output processor

resource "aws_api_gateway_rest_api" "output_processor_api" {
  name        = var.api_gateway_name
  description = "API Gateway for output processor Lambda"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "output_processor_resource" {
  rest_api_id = aws_api_gateway_rest_api.output_processor_api.id
  parent_id   = aws_api_gateway_rest_api.output_processor_api.root_resource_id
  path_part   = "process"
}

# Request validator for AI processor security
resource "aws_api_gateway_request_validator" "ai_processor_validator" {
  name                        = "${var.api_gateway_name}-validator"
  rest_api_id                 = aws_api_gateway_rest_api.output_processor_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_method" "output_processor_method" {
  rest_api_id      = aws_api_gateway_rest_api.output_processor_api.id
  resource_id      = aws_api_gateway_resource.output_processor_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = var.api_key_required

  # Request validation parameters
  request_parameters = {
    "method.request.header.Content-Type"  = true
    "method.request.header.Authorization" = false # Optional for internal API calls
  }

  request_validator_id = aws_api_gateway_request_validator.ai_processor_validator.id
}

resource "aws_api_gateway_integration" "output_processor_integration" {
  rest_api_id = aws_api_gateway_rest_api.output_processor_api.id
  resource_id = aws_api_gateway_resource.output_processor_resource.id
  http_method = aws_api_gateway_method.output_processor_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.output_processor.invoke_arn
}

resource "aws_api_gateway_deployment" "output_processor_deployment" {
  depends_on = [
    aws_api_gateway_integration.output_processor_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.output_processor_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.output_processor_method,
      aws_api_gateway_integration.output_processor_integration
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch log group for API Gateway access logs
# checkov:skip=CKV_AWS_158:Using default CloudWatch encryption per ADR-0006 (no KMS keys)
# checkov:skip=CKV_AWS_338:7 days retention is cost-effective and sufficient for operational debugging (documented decision)
# trivy:ignore:AVD-AWS-0017 Using default CloudWatch encryption per ADR-0006 (no KMS keys)
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.api_gateway_name}"
  retention_in_days = var.log_retention_days
  # Note: CloudWatch Logs uses AWS managed encryption by default
  # Custom KMS keys require additional permissions that may not be available

  tags = var.tags
}

# checkov:skip=CKV2_AWS_29:WAF not required for internal/regional API Gateway per security requirements
# checkov:skip=CKV_AWS_76:Access logging enabled via access_log_settings
# checkov:skip=CKV_AWS_120:Caching not applicable for Lambda-backed APIs with dynamic content
resource "aws_api_gateway_stage" "output_processor_stage" {
  deployment_id = aws_api_gateway_deployment.output_processor_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.output_processor_api.id
  stage_name    = var.stage_name

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.tags
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "output_processor_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.output_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.output_processor_api.execution_arn}/*/*"
}

# API Key for output processor authentication
resource "aws_api_gateway_api_key" "output_processor_key" {
  count = var.api_key_required ? 1 : 0

  name        = "${var.api_gateway_name}-key"
  description = "API Key for AI output processor authentication"

  tags = var.tags
}

resource "aws_api_gateway_usage_plan" "output_processor_usage_plan" {
  name = "${var.api_gateway_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.output_processor_api.id
    stage  = aws_api_gateway_stage.output_processor_stage.stage_name
  }

  tags = var.tags
}

resource "aws_api_gateway_usage_plan_key" "output_processor_usage_plan_key" {
  count = var.api_key_required ? 1 : 0

  key_id        = aws_api_gateway_api_key.output_processor_key[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.output_processor_usage_plan.id
}


