# Security Module for Telegram Bot
# Uses shared security sub-module

module "security" {
  source = "../../core/security"

  function_name          = var.function_name
  api_gateway_name       = "telegram-bot" # Telegram doesn't have API Gateway
  stage_name             = "prod"
  enable_security_alarms = var.enable_security_alarms
  tags                   = var.tags
}
