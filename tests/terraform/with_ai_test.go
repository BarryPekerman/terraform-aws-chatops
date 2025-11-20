package terraform

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestWithAIExample(t *testing.T) {
	t.Parallel()

	// Skip if running in CI without AWS credentials
	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	// Get test configuration
	config := GetDefaultTestConfig(t)

	// Get the example directory path
	exampleDir, err := filepath.Abs("../../examples/with-ai")
	require.NoError(t, err)

	// Setup Terraform options with AI processing enabled
	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{
		"enable_ai_processing": true,
		"ai_model_id":           "anthropic.claude-3-haiku-20240307-v1:0",
		"ai_threshold":          5000,
		"enable_security_alarms": false,
	})

	// Cleanup on exit
	defer CleanupTerraformOptions(t, terraformOptions)

	// Deploy infrastructure
	t.Log("Deploying with-ai example...")
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	t.Log("Validating outputs...")
	outputs := terraform.OutputAll(t, terraformOptions)

	// Verify Secrets Manager secret
	secretARN := outputs["secrets_manager_arn"].(string)
	require.NotEmpty(t, secretARN)
	ValidateSecretsManagerSecret(t, config.Region, secretARN)

	// Verify webhook Lambda
	webhookFunctionARN := outputs["webhook_function_arn"].(string)
	require.NotEmpty(t, webhookFunctionARN)
	ValidateLambdaFunction(t, config.Region, aws.ExtractResourceNameFromArn(t, webhookFunctionARN), "webhook-handler")

	// Verify Telegram bot Lambda
	telegramFunctionARN := outputs["telegram_bot_function_arn"].(string)
	require.NotEmpty(t, telegramFunctionARN)
	ValidateLambdaFunction(t, config.Region, aws.ExtractResourceNameFromArn(t, telegramFunctionARN), "telegram-bot")

	// Verify AI processor Lambda exists (key difference from basic example)
	aiProcessorARN, hasAIProcessor := outputs["ai_processor_function_arn"]
	require.True(t, hasAIProcessor, "AI processor should exist in with-ai example")
	require.NotEmpty(t, aiProcessorARN)

	aiProcessorARNStr := aiProcessorARN.(string)
	ValidateLambdaFunction(t, config.Region, aws.ExtractResourceNameFromArn(t, aiProcessorARNStr), "ai-output-processor")

	// Verify AI processor Lambda invoke ARN exists (direct invoke, no API Gateway by default)
	aiProcessorInvokeARN, hasInvokeARN := outputs["ai_processor_lambda_invoke_arn"]
	assert.True(t, hasInvokeARN, "AI processor invoke ARN should exist")
	assert.NotEmpty(t, aiProcessorInvokeARN)

	// Verify GitHub OIDC provider
	oidcProviderARN := outputs["oidc_provider_arn"].(string)
	require.NotEmpty(t, oidcProviderARN)

	// Verify GitHub IAM role
	githubRoleARN := outputs["github_role_arn"].(string)
	require.NotEmpty(t, githubRoleARN)
	ValidateIAMRole(t, config.Region, githubRoleARN)

	// Verify AI processor URL is optional (only set if use_api_gateway is true)
	_, hasAIProcessorURL := outputs["ai_processor_url"]
	// URL may or may not exist depending on configuration (default is false, no API Gateway)
	// This is acceptable - direct Lambda invoke is the default

	t.Log("With-AI example test completed successfully")
}







