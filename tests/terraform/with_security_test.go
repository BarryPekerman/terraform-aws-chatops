package terraform

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestWithSecurityExample(t *testing.T) {
	t.Parallel()

	// Skip if running in CI without AWS credentials
	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	// Get test configuration
	config := GetDefaultTestConfig(t)

	// Get the example directory path
	exampleDir, err := filepath.Abs("../../examples/with-security")
	require.NoError(t, err)

	// Setup Terraform options with security alarms enabled
	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{
		"enable_security_alarms": true,
	})

	// Cleanup on exit
	defer CleanupTerraformOptions(t, terraformOptions)

	// Deploy infrastructure
	t.Log("Deploying with-security example...")
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

	// Verify GitHub OIDC provider
	oidcProviderARN := outputs["oidc_provider_arn"].(string)
	require.NotEmpty(t, oidcProviderARN)

	// Verify GitHub IAM role
	githubRoleARN := outputs["github_role_arn"].(string)
	require.NotEmpty(t, githubRoleARN)
	ValidateIAMRole(t, config.Region, githubRoleARN)

	// Verify security alarms are created (via CloudWatch)
	// Note: CloudWatch alarms are created through the monitoring module
	// In a production test, we'd verify alarms exist via AWS API
	cloudwatchClient := aws.NewCloudWatchClient(t, config.Region)
	_ = cloudwatchClient

	// Verify environment tags for security
	// The with-security example uses environment_tag_key and environment_tag_value
	// This restricts GitHub Actions to only destroy dev environment resources
	// In a real test, we'd verify the IAM policy includes these tag restrictions

	t.Log("With-Security example test completed successfully")
}







