# Testing Strategy for ChatOps Terraform Module

This directory contains comprehensive tests for the ChatOps Terraform module, including infrastructure integration tests, Lambda function tests, security validation tests, and end-to-end workflow tests.

## Test Structure

```
tests/
├── terraform/          # Terratest infrastructure integration tests
│   ├── go.mod
│   ├── test_helpers.go
│   ├── basic_test.go
│   ├── with_ai_test.go
│   └── with_security_test.go
├── lambda/             # Lambda function unit tests (Python/pytest)
│   ├── requirements.txt
│   ├── conftest.py
│   ├── webhook-handler/
│   │   └── test_webhook_handler.py
│   ├── telegram-bot/
│   │   └── test_bot.py
│   └── ai-processor/
│       └── test_processor.py
├── security/           # IAM policy validation and security tests
│   ├── iam_validation_test.go
│   └── permission_test.go
└── integration/        # End-to-end integration tests
    ├── test_helpers.go
    └── e2e_test.go
```

## Test Types

### 1. Infrastructure Integration Tests (Terratest)

Location: `tests/terraform/`

Tests that deploy actual infrastructure and validate:
- Module deployment and resource creation
- Lambda function configuration
- API Gateway setup
- Secrets Manager integration
- IAM roles and policies
- CloudWatch log groups
- Output validation

**Running Tests:**

```bash
cd tests/terraform
go mod download
go test -v -timeout 30m -run TestBasicExample
```

**Required Environment Variables:**

- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_DEFAULT_REGION` - AWS region (defaults to us-east-1)
- `SKIP_TERRATEST=true` - Skip tests (for CI without AWS credentials)

### 2. Lambda Function Tests

Location: `tests/lambda/`

Unit tests for Lambda functions using pytest and moto for AWS mocking.

**Running Tests:**

```bash
cd tests/lambda
pip install -r requirements.txt
pytest -v --cov=. --cov-report=html
```

**Test Coverage:**
- Webhook handler: Message parsing, callback handling, GitHub API integration, AI processor invocation
- Telegram bot: Message sending, formatting, Markdown parsing
- AI processor: Bedrock integration, output parsing, deduplication, summarization

### 3. Security Validation Tests

Location: `tests/security/`

Tests that validate IAM policies and security configurations:
- IAM policy structure validation
- Tag-based resource access restrictions
- No wildcard permissions (except necessary)
- Secrets Manager access scoping
- OIDC trust relationships

**Running Tests:**

```bash
cd tests/security
go test -v -timeout 20m -run TestIAMPolicyStructure
```

### 4. End-to-End Integration Tests

Location: `tests/integration/`

Tests that simulate complete workflows:
- Full workflow: Telegram → GitHub → Callback → Reply
- Error scenarios: Invalid requests, missing secrets, network errors
- AI processing workflow: Long output → AI processor → Formatted reply

**Running Tests:**

```bash
cd tests/integration
go test -v -timeout 30m -run TestEndToEndWorkflow
```

## CI/CD Integration

Tests are automatically run in GitHub Actions:

- **Pull Requests**: Run basic Terratest, Lambda unit tests, IAM validation
- **Main Branch**: Run full integration tests for all examples

See `.github/workflows/integration-tests.yml` for details.

## Local Testing

### Prerequisites

1. **Go 1.21+** - For Terratest
2. **Python 3.11+** - For Lambda tests
3. **Terraform 1.6.0+** - For infrastructure tests
4. **AWS Credentials** - Configured via `~/.aws/credentials` or environment variables

### Running All Tests

```bash
# Install dependencies
cd tests/terraform && go mod download && cd ../..
cd tests/lambda && pip install -r requirements.txt && cd ../..

# Run infrastructure tests
cd tests/terraform
go test -v -timeout 30m ./...

# Run Lambda tests
cd ../lambda
pytest -v

# Run security tests
cd ../security
go test -v -timeout 20m ./...

# Run integration tests
cd ../integration
go test -v -timeout 30m ./...
```

### Test Environment Setup

For local testing, create a test AWS account or use a dedicated test environment:

1. Create test S3 bucket for Terraform state
2. Set up test Secrets Manager secrets
3. Configure test GitHub repository (or use mocks)
4. Configure test Telegram bot (or use mocks)

**Note:** Tests create and destroy real AWS resources. Use a test account!

## Adding New Tests

### Adding a New Terratest

1. Create test file in `tests/terraform/`
2. Import test helpers: `import "../terraform"`
3. Use `SetupTerraformOptions()` and `CleanupTerraformOptions()`
4. Add validation functions using Terratest helpers

Example:

```go
func TestNewExample(t *testing.T) {
    t.Parallel()
    
    config := GetDefaultTestConfig(t)
    exampleDir, _ := filepath.Abs("../../examples/new-example")
    
    terraformOptions := SetupTerraformOptions(t, exampleDir, config, map[string]interface{}{})
    defer CleanupTerraformOptions(t, terraformOptions)
    
    terraform.InitAndApply(t, terraformOptions)
    
    // Add validation...
}
```

### Adding a New Lambda Test

1. Create test file in `tests/lambda/<function-name>/`
2. Use pytest fixtures from `conftest.py`
3. Mock AWS services with moto
4. Test error handling and edge cases

Example:

```python
def test_new_functionality(sample_api_gateway_event, mock_secrets_manager):
    # Test implementation
    pass
```

## Troubleshooting

### Tests Fail with "Missing Lambda ZIP files"

Ensure Lambda ZIP files exist before running tests. Tests create dummy ZIPs if missing, but actual deployment requires real ZIPs.

### Tests Fail with AWS Credentials

Ensure AWS credentials are configured:
```bash
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

### Tests Timeout

Increase timeout:
```bash
go test -v -timeout 60m ...
```

### Skip Tests in CI

Set environment variable:
```bash
export SKIP_TERRATEST=true
```

## Test Data

Tests use dummy data for:
- GitHub tokens: `dummy-token-12345`
- Telegram bot tokens: `123456:ABC-DEF-dummy-token`
- Chat IDs: `123456789`
- S3 bucket ARNs: Generated with random IDs

**Important:** Never commit real secrets to tests!

## Contributing

When adding new features:
1. Add corresponding Terratest to validate infrastructure
2. Add Lambda unit tests for new Lambda functionality
3. Add security tests for new IAM policies
4. Update integration tests if workflows change

## Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Pytest Documentation](https://docs.pytest.org/)
- [Moto Documentation](https://docs.getmoto.org/)







