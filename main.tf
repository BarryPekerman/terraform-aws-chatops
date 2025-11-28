# ChatOps Terraform Module v0.1.0
# Root module orchestrating core, CI/CD, and chat integrations

# Core Secrets Module
module "core_secrets" {
  source = "./modules/core/secrets"

  name_prefix        = var.name_prefix
  github_token       = var.github_token
  telegram_bot_token = var.telegram_bot_token
  api_gateway_key    = random_password.api_key.result

  tags = var.tags
}

# Core Webhook Handler Module
module "core_webhook" {
  source = "./modules/core/webhook-handler"

  function_name               = "${var.name_prefix}-webhook-handler"
  api_gateway_name            = "${var.name_prefix}-webhook-api"
  lambda_zip_path             = var.webhook_lambda_zip_path
  github_owner                = var.github_owner
  github_repo                 = var.github_repo
  authorized_chat_id          = var.authorized_chat_id
  secrets_manager_arn         = module.core_secrets.secret_arn
  project_registry_secret_arn = module.core_secrets.project_registry_secret_arn
  ai_processor_function_arn   = module.ai_processor.processor_function_arn
  ai_threshold                = var.ai_threshold
  max_message_length          = var.max_message_length

  stage_name             = var.api_gateway_stage
  log_retention_days     = var.log_retention_days
  enable_xray_tracing    = var.enable_xray_tracing
  enable_kms_encryption  = true
  enable_dlq             = true
  rate_limit             = var.rate_limit
  burst_limit            = var.burst_limit
  quota_limit            = var.quota_limit
  quota_period           = var.quota_period
  api_key_required       = var.webhook_api_key_required
  additional_env_vars    = var.webhook_additional_env_vars
  enable_security_alarms = var.enable_security_alarms

  tags = var.tags

  depends_on = [module.core_secrets, module.ai_processor]
}

# GitHub OIDC and IAM Module
module "github" {
  source = "./modules/cicd/github"

  role_name                   = "${var.name_prefix}-github-actions-role"
  github_owner                = var.github_owner
  github_repo                 = var.github_repo
  github_branch               = var.github_branch
  secrets_manager_arn         = module.core_secrets.secret_arn
  project_registry_secret_arn = module.core_secrets.project_registry_secret_arn
  s3_bucket_arn               = var.s3_bucket_arn
  resource_tag_key            = var.resource_tag_key
  resource_tag_value          = var.resource_tag_value

  tags = var.tags

  depends_on = [module.core_secrets]
}

# Telegram Bot Module
module "telegram" {
  source = "./modules/chat/telegram"

  function_name          = "${var.name_prefix}-telegram-bot"
  lambda_zip_path        = var.telegram_lambda_zip_path
  api_gateway_url        = module.core_webhook.api_gateway_url
  authorized_chat_id     = var.authorized_chat_id
  secrets_manager_arn    = module.core_secrets.secret_arn
  log_retention_days     = var.log_retention_days
  enable_kms_encryption  = true
  enable_dlq             = true
  additional_env_vars    = var.telegram_additional_env_vars
  enable_security_alarms = var.enable_security_alarms

  tags = var.tags

  depends_on = [module.core_webhook, module.core_secrets]
}

# AI Output Processor Module (Core - always deployed)
module "ai_processor" {
  source = "./modules/core/ai-output-processor"

  function_name          = "${var.name_prefix}-ai-processor"
  api_gateway_name       = "${var.name_prefix}-ai-processor-api"
  lambda_zip_path        = var.ai_processor_lambda_zip_path
  enable_ai_processing   = var.enable_ai_processing
  max_message_length     = var.max_message_length
  ai_threshold           = var.ai_threshold
  ai_model_id            = var.ai_model_id
  ai_max_tokens          = var.ai_max_tokens
  secrets_manager_arn    = module.core_secrets.secret_arn
  log_retention_days     = var.log_retention_days
  additional_env_vars    = var.ai_processor_additional_env_vars
  enable_security_alarms = var.enable_security_alarms

  tags = var.tags

  depends_on = [module.core_secrets]
}

# Random password for API Gateway key
resource "random_password" "api_key" {
  length  = 32
  special = true
}

# Monitoring Module
module "monitoring" {
  source = "./modules/core/monitoring"

  dashboard_name = "${var.name_prefix}-dashboard"

  webhook_function_name      = module.core_webhook.lambda_function_name
  telegram_function_name     = module.telegram.bot_function_name
  ai_processor_function_name = var.enable_ai_processing ? module.ai_processor.processor_function_name : ""

  webhook_api_name   = "${var.name_prefix}-webhook-api"
  webhook_stage_name = var.api_gateway_stage
  ai_api_name        = var.enable_ai_processing ? "${var.name_prefix}-ai-processor-api" : ""
  ai_stage_name      = var.api_gateway_stage

  webhook_log_group      = "/aws/lambda/${module.core_webhook.lambda_function_name}"
  telegram_log_group     = "/aws/lambda/${module.telegram.bot_function_name}"
  ai_processor_log_group = var.enable_ai_processing ? "/aws/lambda/${module.ai_processor.processor_function_name}" : ""

  enable_security_alarms      = var.enable_security_alarms
  high_request_rate_threshold = var.high_request_rate_threshold
  high_error_rate_threshold   = var.high_error_rate_threshold

  tags = var.tags

  depends_on = [
    module.core_webhook,
    module.telegram,
    module.ai_processor
  ]
}

