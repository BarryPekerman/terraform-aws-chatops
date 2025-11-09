# Security Module for Webhook Handler
# Uses shared security sub-module

module "security" {
  source = "../security"

  function_name          = var.function_name
  api_gateway_name       = aws_api_gateway_rest_api.webhook_api.name
  stage_name             = var.stage_name
  enable_security_alarms = var.enable_security_alarms
  tags                   = var.tags
}
