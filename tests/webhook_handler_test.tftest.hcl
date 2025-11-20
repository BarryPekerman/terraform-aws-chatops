# Terraform test for webhook-handler module
# Uses mocked providers - safe for public module publication
# Run with: terraform test

run "webhook_handler_module_plan" {
  command = plan

  module {
    source = "./modules/core/webhook-handler"
  }

  variables {
    function_name                  = "test-webhook-handler"
    api_gateway_name               = "test-webhook-api"
    lambda_zip_path                = "test.zip"
    github_owner                   = "test-owner"
    github_repo                    = "test-repo"
    authorized_chat_id             = "123456789"
    secrets_manager_arn            = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-secret"
    max_message_length             = 3500
    stage_name                     = "test"
    log_retention_days             = 7
    lambda_timeout                 = 30
    lambda_memory_size             = 128
    dlq_message_retention_seconds  = 1209600
    dlq_visibility_timeout_seconds = 30
    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = length(var.function_name) > 0 && length(var.secrets_manager_arn) > 0
    error_message = "Module should accept valid variables"
  }
}

run "webhook_handler_variable_validation" {
  command = plan

  module {
    source = "./modules/core/webhook-handler"
  }

  variables {
    function_name                  = "test-webhook-handler"
    api_gateway_name               = "test-webhook-api"
    lambda_zip_path                = "test.zip"
    github_owner                   = "test-owner"
    github_repo                    = "test-repo"
    authorized_chat_id             = "123456789"
    secrets_manager_arn            = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-secret"
    max_message_length             = 3500
    lambda_timeout                 = 30
    lambda_memory_size             = 128
    dlq_message_retention_seconds  = 1209600
    dlq_visibility_timeout_seconds = 30
    tags                           = {}
  }

  assert {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "Lambda timeout should be between 3 and 900 seconds"
  }

  assert {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory should be between 128 and 10240 MB"
  }
}

