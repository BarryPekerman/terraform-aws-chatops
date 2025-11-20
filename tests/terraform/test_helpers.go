package terraform

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

// TestConfig holds common test configuration
type TestConfig struct {
	Region           string
	NamePrefix       string
	GitHubOwner      string
	GitHubRepo       string
	GitHubBranch     string
	AuthorizedChatID string
	S3BucketARN      string
}

// GetDefaultTestConfig returns a default test configuration with random name prefix
func GetDefaultTestConfig(t *testing.T) TestConfig {
	region := aws.GetRandomRegion(t, nil, nil)
	uniqueID := random.UniqueId()

	return TestConfig{
		Region:           region,
		NamePrefix:       fmt.Sprintf("terratest-%s", uniqueID),
		GitHubOwner:      "test-org",
		GitHubRepo:       "test-repo",
		GitHubBranch:     "main",
		AuthorizedChatID: "123456789",
		S3BucketARN:      fmt.Sprintf("arn:aws:s3:::test-bucket-%s", uniqueID),
	}
}

// CreateDummyLambdaZIP creates a minimal dummy ZIP file for testing
func CreateDummyLambdaZIP(t *testing.T, zipPath string) {
	// Create a minimal valid ZIP file
	zipContent := []byte{
		0x50, 0x4B, 0x03, 0x04, // ZIP file signature
		0x14, 0x00, // Version
		0x00, 0x00, // Flags
		0x08, 0x00, // Compression method
		0x00, 0x00, 0x00, 0x00, // Time
		0x00, 0x00, 0x00, 0x00, // Date
		0x00, 0x00, 0x00, 0x00, // CRC32
		0x00, 0x00, 0x00, 0x00, // Compressed size
		0x00, 0x00, 0x00, 0x00, // Uncompressed size
		0x00, 0x00, // Filename length
		0x00, 0x00, // Extra field length
	}

	dir := filepath.Dir(zipPath)
	err := os.MkdirAll(dir, 0755)
	require.NoError(t, err)

	err = os.WriteFile(zipPath, zipContent, 0644)
	require.NoError(t, err)
}

// SetupTerraformOptions creates Terraform options with common settings
func SetupTerraformOptions(t *testing.T, exampleDir string, config TestConfig, vars map[string]interface{}) *terraform.Options {
	// Create dummy Lambda ZIP files for testing if they don't exist
	lambdaZips := []string{
		"lambda_function.zip",
		"telegram-bot.zip",
		"output_processor.zip",
	}

	for _, zipFile := range lambdaZips {
		zipPath := filepath.Join(exampleDir, zipFile)
		if _, err := os.Stat(zipPath); os.IsNotExist(err) {
			CreateDummyLambdaZIP(t, zipPath)
		}
	}

	// Merge with default vars
	defaultVars := map[string]interface{}{
		"aws_region":         config.Region,
		"name_prefix":        config.NamePrefix,
		"github_owner":       config.GitHubOwner,
		"github_repo":        config.GitHubRepo,
		"github_branch":      config.GitHubBranch,
		"authorized_chat_id": config.AuthorizedChatID,
		"s3_bucket_arn":      config.S3BucketARN,
		"github_token":       "dummy-token-12345",
		"telegram_bot_token": "123456:ABC-DEF-dummy-token",
	}

	// Merge user vars (override defaults)
	for k, v := range vars {
		defaultVars[k] = v
	}

	return &terraform.Options{
		TerraformDir: exampleDir,
		Vars:         defaultVars,
		BackendConfig: map[string]interface{}{
			"backend": "false", // Use local backend for tests
		},
		NoColor: true,
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": config.Region,
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
		RetryableTerraformErrors: map[string]string{
			"timeout while waiting for state to become": "Terraform apply timeout",
		},
	}
}

// CleanupTerraformOptions cleans up Terraform options and resources
func CleanupTerraformOptions(t *testing.T, terraformOptions *terraform.Options) {
	terraform.Destroy(t, terraformOptions)
}

// ValidateLambdaFunction validates that a Lambda function exists and has correct properties
func ValidateLambdaFunction(t *testing.T, region, functionName, expectedRolePrefix string) {
	lambda := aws.GetLambdaFunction(t, region, functionName)
	require.NotNil(t, lambda)

	// Verify function exists
	require.Equal(t, functionName, *lambda.FunctionName)

	// Verify IAM role is set
	require.NotEmpty(t, lambda.Role)

	// Verify role contains expected prefix
	if expectedRolePrefix != "" {
		require.Contains(t, *lambda.Role, expectedRolePrefix)
	}
}

// ValidateSecretsManagerSecret validates that a Secrets Manager secret exists
func ValidateSecretsManagerSecret(t *testing.T, region, secretARN string) {
	secret := aws.GetSecretsManagerSecret(t, region, secretARN)
	require.NotNil(t, secret)
	require.Equal(t, secretARN, *secret.ARN)
}

// ValidateIAMRole validates that an IAM role exists
func ValidateIAMRole(t *testing.T, region, roleARN string) {
	role := aws.GetIamRole(t, region, roleARN)
	require.NotNil(t, role)
	require.Equal(t, roleARN, *role.Arn)
}

// ValidateAPIGateway validates API Gateway endpoint exists
func ValidateAPIGateway(t *testing.T, region, apiGatewayURL string) {
	// API Gateway URL should be non-empty and start with https://
	require.NotEmpty(t, apiGatewayURL)
	require.Contains(t, apiGatewayURL, "https://")
	require.Contains(t, apiGatewayURL, ".execute-api.")
}







