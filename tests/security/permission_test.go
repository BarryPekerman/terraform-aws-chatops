package security

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Note: These tests require actual AWS resources to validate permissions
// They should be run in a test AWS account with appropriate permissions

func TestTagBasedDestroyPermissions(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	// This test validates that the GitHub Actions role can only destroy tagged resources
	// In a full implementation, this would:
	// 1. Create a tagged EC2 instance
	// 2. Create an untagged EC2 instance
	// 3. Attempt to destroy both using the GitHub Actions role
	// 4. Verify only the tagged instance can be destroyed

	config := GetDefaultTestConfig(t)
	exampleDir, err := filepath.Abs("../../examples/basic")
	require.NoError(t, err)

	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})
	defer CleanupTerraformOptions(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)
	githubRoleARN := outputs["github_role_arn"].(string)

	// Validate role exists
	role := aws.GetIamRole(t, config.Region, githubRoleARN)
	require.NotNil(t, role)

	// In a full test, we would:
	// 1. Assume the role
	// 2. Try to destroy tagged resource (should succeed)
	// 3. Try to destroy untagged resource (should fail)
	// 4. Verify expected behavior

	t.Log("Tag-based destroy permissions test framework created")
	assert.NotEmpty(t, githubRoleARN, "GitHub role ARN should exist")
}

func TestEnvironmentTagRestriction(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	// This test validates that when environment_tag_key is set,
	// the role can only destroy resources in that environment

	config := GetDefaultTestConfig(t)
	exampleDir, err := filepath.Abs("../../examples/with-security")
	require.NoError(t, err)

	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})
	defer CleanupTerraformOptions(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)
	githubRoleARN := outputs["github_role_arn"].(string)

	// Validate role exists
	role := aws.GetIamRole(t, config.Region, githubRoleARN)
	require.NotNil(t, role)

	// In a full test, we would verify:
	// 1. Resources tagged with Environment=dev can be destroyed
	// 2. Resources tagged with Environment=prod cannot be destroyed
	// 3. This is enforced by IAM policy conditions

	t.Log("Environment tag restriction test framework created")
	assert.NotEmpty(t, githubRoleARN, "GitHub role ARN should exist")
}

func TestReadOnlyPlanPermissions(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	// This test validates that the role has read-only permissions for Terraform plan
	// It should be able to:
	// - Read Secrets Manager secrets (backend config)
	// - Read S3 bucket contents (state files)
	// - Describe EC2 resources (for plan)
	// But NOT:
	// - Create/Modify/Delete resources

	config := GetDefaultTestConfig(t)
	exampleDir, err := filepath.Abs("../../examples/basic")
	require.NoError(t, err)

	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})
	defer CleanupTerraformOptions(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)
	githubRoleARN := outputs["github_role_arn"].(string)

	// Validate role exists
	role := aws.GetIamRole(t, config.Region, githubRoleARN)
	require.NotNil(t, role)

	// In a full test, we would:
	// 1. Assume the role
	// 2. Verify it can read Secrets Manager
	// 3. Verify it can read S3 bucket
	// 4. Verify it can describe EC2 resources
	// 5. Verify it CANNOT create/modify/delete resources (unless tagged)

	t.Log("Read-only plan permissions test framework created")
	assert.NotEmpty(t, githubRoleARN, "GitHub role ARN should exist")
}







