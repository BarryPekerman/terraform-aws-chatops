package integration

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

// SetupTerraformOptions creates Terraform options with common settings
func SetupTerraformOptions(t *testing.T, exampleDir string, config TestConfig, vars map[string]interface{}) *terraform.Options {
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







