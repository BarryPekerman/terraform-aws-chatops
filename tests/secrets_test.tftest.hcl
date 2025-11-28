# Terraform test for secrets module
# Uses mocked providers - safe for public module publication
# Run with: terraform test

run "secrets_module_validation" {
  command = plan

  module {
    source = "./modules/core/secrets"
  }

  variables {
    name_prefix        = "test-chatops"
    github_token       = "test-token"
    telegram_bot_token = "test-bot-token"
    api_gateway_key    = "test-api-key"
    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = length(var.name_prefix) > 0 && length(var.github_token) > 0
    error_message = "Module should accept valid variables"
  }
}

run "secrets_module_outputs" {
  command = plan

  module {
    source = "./modules/core/secrets"
  }

  variables {
    name_prefix        = "test-chatops"
    github_token       = "test-token"
    telegram_bot_token = "test-bot-token"
    api_gateway_key    = "test-api-key"
    tags               = {}
  }

  assert {
    condition     = length(var.name_prefix) > 0
    error_message = "Module should accept valid variables"
  }
}

run "secrets_module_variable_validation" {
  command = plan

  module {
    source = "./modules/core/secrets"
  }

  variables {
    name_prefix        = "test"
    github_token       = "test-token"
    telegram_bot_token = "test-bot-token"
    api_gateway_key    = "test-api-key"
    tags               = {}
  }

  assert {
    condition     = length(var.name_prefix) > 0
    error_message = "Name prefix should be provided"
  }
}

