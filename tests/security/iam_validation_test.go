package security

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIAMPolicyStructure(t *testing.T) {
	t.Parallel()

	// Skip if running in CI without AWS credentials
	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	// Get test configuration
	config := GetDefaultTestConfig(t)

	// Get the example directory path
	exampleDir, err := filepath.Abs("../../examples/basic")
	require.NoError(t, err)

	// Setup Terraform options
	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})

	// Cleanup on exit
	defer CleanupTerraformOptions(t, terraformOptions)

	// Deploy infrastructure
	t.Log("Deploying infrastructure for IAM validation...")
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	outputs := terraform.OutputAll(t, terraformOptions)
	githubRoleARN := outputs["github_role_arn"].(string)

	// Validate IAM role exists
	t.Log("Validating IAM role structure...")
	role := aws.GetIamRole(t, config.Region, githubRoleARN)
	require.NotNil(t, role)
	assert.NotEmpty(t, role.Arn)

	// Get attached policies
	policies := aws.ListIamRolePolicies(t, config.Region, *role.RoleName)
	require.NotEmpty(t, policies, "Role should have attached policies")

	// Validate policy structure
	t.Log("Validating IAM policy structure...")
	for _, policyName := range policies {
		policy := aws.GetIamPolicy(t, config.Region, policyName)

		// Get policy document
		policyVersion := aws.GetIamPolicyVersion(t, config.Region, policyName, *policy.DefaultVersionId)
		require.NotNil(t, policyVersion)

		// Parse policy document
		var policyDoc map[string]interface{}
		err := json.Unmarshal([]byte(*policyVersion.Document), &policyDoc)
		require.NoError(t, err)

		// Validate policy structure
		assert.Equal(t, "2012-10-17", policyDoc["Version"], "Policy should use 2012-10-17 version")

		statements, ok := policyDoc["Statement"].([]interface{})
		require.True(t, ok, "Policy should have Statement array")

		// Validate each statement
		for _, stmt := range statements {
			stmtMap, ok := stmt.(map[string]interface{})
			require.True(t, ok, "Statement should be a map")

			// Validate required fields
			_, hasEffect := stmtMap["Effect"]
			assert.True(t, hasEffect, "Statement should have Effect")

			_, hasAction := stmtMap["Action"]
			assert.True(t, hasAction, "Statement should have Action")
		}
	}

	t.Log("IAM policy structure validation completed")
}

func TestTagBasedResourceAccess(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	config := GetDefaultTestConfig(t)
	exampleDir, err := filepath.Abs("../../examples/basic")
	require.NoError(t, err)

	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})
	defer CleanupTerraformOptions(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)
	githubRoleARN := outputs["github_role_arn"].(string)

	// Get the tagged resource destroy policy
	role := aws.GetIamRole(t, config.Region, githubRoleARN)
	policies := aws.ListIamRolePolicies(t, config.Region, *role.RoleName)

	// Find the tagged resource destroy policy
	var destroyPolicyARN string
	for _, policyName := range policies {
		if contains(*policyName, "tagged-resource-destroy") {
			policy := aws.GetIamPolicy(t, config.Region, policyName)
			destroyPolicyARN = *policy.Arn
			break
		}
	}

	require.NotEmpty(t, destroyPolicyARN, "Tagged resource destroy policy should exist")

	// Get policy document
	policy := aws.GetIamPolicy(t, config.Region, destroyPolicyARN)
	policyVersion := aws.GetIamPolicyVersion(t, config.Region, destroyPolicyARN, *policy.DefaultVersionId)

	var policyDoc map[string]interface{}
	err = json.Unmarshal([]byte(*policyVersion.Document), &policyDoc)
	require.NoError(t, err)

	statements := policyDoc["Statement"].([]interface{})

	// Validate that all destroy statements have tag conditions
	for _, stmt := range statements {
		stmtMap := stmt.(map[string]interface{})
		actions := stmtMap["Action"].([]interface{})

		// Check if any action is a destroy/delete action
		hasDestroyAction := false
		for _, action := range actions {
			actionStr := action.(string)
			if contains(actionStr, "Delete") || contains(actionStr, "Terminate") || contains(actionStr, "Remove") {
				hasDestroyAction = true
				break
			}
		}

		// If it's a destroy action, it should have tag condition
		if hasDestroyAction {
			condition, hasCondition := stmtMap["Condition"].(map[string]interface{})
			require.True(t, hasCondition, "Destroy statements should have Condition")

			stringEquals, hasStringEquals := condition["StringEquals"].(map[string]interface{})
			require.True(t, hasStringEquals, "Condition should have StringEquals")

			// Check for tag condition
			hasTagCondition := false
			for key := range stringEquals {
				if contains(key, "ResourceTag") || contains(key, "aws:ResourceTag") {
					hasTagCondition = true
					break
				}
			}
			assert.True(t, hasTagCondition, "Destroy statements should have tag-based condition")
		}
	}

	t.Log("Tag-based resource access validation completed")
}

func TestNoWildcardPermissions(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	config := GetDefaultTestConfig(t)
	exampleDir, err := filepath.Abs("../../examples/basic")
	require.NoError(t, err)

	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})
	defer CleanupTerraformOptions(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)
	githubRoleARN := outputs["github_role_arn"].(string)

	role := aws.GetIamRole(t, config.Region, githubRoleARN)
	policies := aws.ListIamRolePolicies(t, config.Region, *role.RoleName)

	// Check all policies for wildcard permissions (excluding necessary ones)
	allowedWildcardActions := []string{
		"ec2:Describe*",      // Read-only operations are acceptable
		"ec2:Get*",           // Read-only operations are acceptable
		"ec2:List*",          // Read-only operations are acceptable
		"xray:PutTraceSegments",    // X-Ray requires wildcard resource
		"xray:PutTelemetryRecords", // X-Ray requires wildcard resource
	}

	for _, policyName := range policies {
		policy := aws.GetIamPolicy(t, config.Region, policyName)
		policyVersion := aws.GetIamPolicyVersion(t, config.Region, policyName, *policy.DefaultVersionId)

		var policyDoc map[string]interface{}
		err := json.Unmarshal([]byte(*policyVersion.Document), &policyDoc)
		require.NoError(t, err)

		statements := policyDoc["Statement"].([]interface{})

		for _, stmt := range statements {
			stmtMap := stmt.(map[string]interface{})
			actions := stmtMap["Action"].([]interface{})
			resources := stmtMap["Resource"]

			// Check for wildcard resources (except for read-only operations)
			if resources != nil {
				resourceList := resources.([]interface{})
				for _, resource := range resourceList {
					resourceStr := resource.(string)
					if resourceStr == "*" {
						// Check if all actions are read-only or allowed wildcards
						allAllowed := true
						for _, action := range actions {
							actionStr := action.(string)
							isAllowed := false
							for _, allowed := range allowedWildcardActions {
								if actionStr == allowed || contains(actionStr, allowed[:len(allowed)-1]) {
									isAllowed = true
									break
								}
							}
							if !isAllowed && (contains(actionStr, "Delete") || contains(actionStr, "Terminate") || contains(actionStr, "Modify") || contains(actionStr, "Put") || contains(actionStr, "Create")) {
								allAllowed = false
								break
							}
						}
						// For destroy actions with wildcard resources, they should have tag conditions
						if !allAllowed {
							condition, hasCondition := stmtMap["Condition"].(map[string]interface{})
							assert.True(t, hasCondition, "Non-read-only wildcard resources should have tag conditions")
							if hasCondition {
								// Verify tag condition exists
								stringEquals, _ := condition["StringEquals"].(map[string]interface{})
								hasTagCondition := false
								for key := range stringEquals {
									if contains(key, "ResourceTag") {
										hasTagCondition = true
										break
									}
								}
								assert.True(t, hasTagCondition, "Destroy actions with wildcard resources must have tag conditions")
							}
						}
					}
				}
			}
		}
	}

	t.Log("Wildcard permissions validation completed")
}

func TestSecretsManagerAccessScoping(t *testing.T) {
	t.Parallel()

	if os.Getenv("SKIP_TERRATEST") == "true" {
		t.Skip("Skipping Terratest - SKIP_TERRATEST=true")
	}

	config := GetDefaultTestConfig(t)
	exampleDir, err := filepath.Abs("../../examples/basic")
	require.NoError(t, err)

	terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})
	defer CleanupTerraformOptions(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)
	githubRoleARN := outputs["github_role_arn"].(string)
	secretARN := outputs["secrets_manager_arn"].(string)

	role := aws.GetIamRole(t, config.Region, githubRoleARN)
	policies := aws.ListIamRolePolicies(t, config.Region, *role.RoleName)

	// Find the Secrets Manager policy
	var secretsPolicyARN string
	for _, policyName := range policies {
		if contains(*policyName, "permissions") {
			policy := aws.GetIamPolicy(t, config.Region, policyName)
			policyVersion := aws.GetIamPolicyVersion(t, config.Region, policyName, *policy.DefaultVersionId)

			var policyDoc map[string]interface{}
			err := json.Unmarshal([]byte(*policyVersion.Document), &policyDoc)
			require.NoError(t, err)

			statements := policyDoc["Statement"].([]interface{})
			for _, stmt := range statements {
				stmtMap := stmt.(map[string]interface{})
				actions := stmtMap["Action"].([]interface{})
				for _, action := range actions {
					if contains(action.(string), "secretsmanager") {
						secretsPolicyARN = *policy.Arn
						break
					}
				}
			}
		}
	}

	require.NotEmpty(t, secretsPolicyARN, "Secrets Manager policy should exist")

	// Verify policy only allows access to specific secret ARN
	policy := aws.GetIamPolicy(t, config.Region, secretsPolicyARN)
	policyVersion := aws.GetIamPolicyVersion(t, config.Region, secretsPolicyARN, *policy.DefaultVersionId)

	var policyDoc map[string]interface{}
	err = json.Unmarshal([]byte(*policyVersion.Document), &policyDoc)
	require.NoError(t, err)

	statements := policyDoc["Statement"].([]interface{})
	for _, stmt := range statements {
		stmtMap := stmt.(map[string]interface{})
		actions := stmtMap["Action"].([]interface{})
		resources := stmtMap["Resource"].([]interface{})

		hasSecretsManagerAction := false
		for _, action := range actions {
			if contains(action.(string), "secretsmanager") {
				hasSecretsManagerAction = true
				break
			}
		}

		if hasSecretsManagerAction {
			// Verify resources are scoped to specific ARNs, not wildcards
			for _, resource := range resources {
				resourceStr := resource.(string)
				assert.NotEqual(t, "*", resourceStr, "Secrets Manager access should be scoped to specific ARNs")
				// Should include the secret ARN
				assert.True(t, contains(resourceStr, secretARN) || contains(secretARN, resourceStr), "Policy should allow access to the created secret")
			}
		}
	}

	t.Log("Secrets Manager access scoping validation completed")
}

// Helper function from test_helpers.go
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 || (len(s) > 0 && len(substr) > 0 && containsHelper(s, substr)))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// Import test helpers
func GetDefaultTestConfig(t *testing.T) interface{} {
	// This would import from terraform test helpers
	// For now, return minimal config
	return map[string]interface{}{
		"Region": "us-east-1",
	}
}

func SetupTerraformOptions(t *testing.T, exampleDir string, config interface{}, vars map[string]interface{}) *terraform.Options {
	// Minimal implementation
	return &terraform.Options{
		TerraformDir: exampleDir,
	}
}

func CleanupTerraformOptions(t *testing.T, terraformOptions *terraform.Options) {
	terraform.Destroy(t, terraformOptions)
}







