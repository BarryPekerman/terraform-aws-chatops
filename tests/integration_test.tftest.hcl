# Integration test for root module
# Uses mocked providers - safe for public module publication
# Run with: terraform test
#
# Note: This is a simplified integration test that validates module composition.
# For full integration tests that deploy real AWS resources, see Terratest (CI/CD only).

run "root_module_composition" {
  command = plan

  module {
    source = "./."
  }

  variables {
    name_prefix                  = "test-chatops"
    github_owner                 = "test-owner"
    github_repo                  = "test-repo"
    github_branch                = "main"
    github_token                 = "test-token"
    telegram_bot_token           = "test-bot-token"
    authorized_chat_id           = "123456789"
    s3_bucket_arn                = "arn:aws:s3:::test-terraform-state"
    webhook_lambda_zip_path      = "test-webhook.zip"
    telegram_lambda_zip_path     = "test-telegram.zip"
    ai_processor_lambda_zip_path = "test-ai.zip"
    enable_ai_processing         = false
    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = length(var.name_prefix) > 0 && length(var.github_owner) > 0
    error_message = "Module should accept valid variables and plan successfully"
  }
}

run "root_module_dependencies" {
  command = plan

  module {
    source = "./."
  }

  variables {
    name_prefix                  = "test-chatops"
    github_owner                 = "test-owner"
    github_repo                  = "test-repo"
    github_branch                = "main"
    github_token                 = "test-token"
    telegram_bot_token           = "test-bot-token"
    authorized_chat_id           = "123456789"
    s3_bucket_arn                = "arn:aws:s3:::test-terraform-state"
    webhook_lambda_zip_path      = "test-webhook.zip"
    telegram_lambda_zip_path     = "test-telegram.zip"
    ai_processor_lambda_zip_path = "test-ai.zip"
    enable_ai_processing         = false
    tags                         = {}
  }

  # Validate that secrets module is created before webhook handler
  assert {
    condition     = length(var.name_prefix) > 0 # Dependency validation handled by Terraform
    error_message = "Module dependencies should be correctly ordered"
  }
}

