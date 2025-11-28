"""
Shared pytest configuration and fixtures for Lambda function tests
"""
import os
import json
from unittest.mock import Mock, patch, MagicMock
import pytest
import boto3
from moto import mock_secretsmanager, mock_lambda as mock_lambda_service


@pytest.fixture
def aws_credentials():
    """Mock AWS credentials for moto"""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
    yield
    # Cleanup
    for key in ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SECURITY_TOKEN", "AWS_SESSION_TOKEN"]:
        os.environ.pop(key, None)


@pytest.fixture
def mock_secrets_manager(aws_credentials):
    """Mock AWS Secrets Manager"""
    with mock_secretsmanager():
        yield boto3.client("secretsmanager", region_name="us-east-1")


@pytest.fixture
def mock_lambda(aws_credentials):
    """Mock AWS Lambda service"""
    with mock_lambda_service():
        yield boto3.client("lambda", region_name="us-east-1")


@pytest.fixture
def test_secret_value():
    """Test secret value structure"""
    return {
        "github_token": "dummy-github-token-12345",
        "telegram_bot_token": "123456:ABC-DEF-dummy-token",
        "api_gateway_key": "dummy-api-key-12345"
    }


@pytest.fixture
def sample_telegram_message():
    """Sample Telegram webhook message"""
    return {
        "message": {
            "message_id": 1,
            "chat": {
                "id": 123456789,
                "type": "private"
            },
            "text": "/status",
            "date": 1640000000
        }
    }


@pytest.fixture
def sample_callback_message():
    """Sample callback message from GitHub Actions"""
    return {
        "callback": True,
        "chat_id": "123456789",
        "command": "status",
        "raw_output": "Terraform state output...",
        "run_id": "12345"
    }


@pytest.fixture
def sample_api_gateway_event():
    """Sample API Gateway event"""
    return {
        "httpMethod": "POST",
        "path": "/webhook",
        "headers": {
            "Content-Type": "application/json",
            "x-api-key": "dummy-api-key-12345"
        },
        "body": json.dumps({
            "message": {
                "chat": {"id": 123456789},
                "text": "/status"
            }
        }),
        "requestContext": {
            "requestId": "test-request-id",
            "stage": "test"
        }
    }


@pytest.fixture
def sample_lambda_context():
    """Sample Lambda context"""
    context = Mock()
    context.function_name = "test-function"
    context.function_version = "1"
    context.invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test-function"
    context.memory_limit_in_mb = "128"
    context.aws_request_id = "test-request-id"
    context.log_group_name = "/aws/lambda/test-function"
    context.log_stream_name = "2024/01/01/[$LATEST]test"
    return context


@pytest.fixture
def mock_telegram_api():
    """Mock Telegram API responses"""
    with patch("requests.post") as mock_post:
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"ok": True, "result": {"message_id": 1}}
        mock_post.return_value = mock_response
        yield mock_post


@pytest.fixture
def mock_github_api():
    """Mock GitHub API responses"""
    with patch("requests.post") as mock_post:
        mock_response = Mock()
        mock_response.status_code = 204
        mock_post.return_value = mock_response
        yield mock_post


@pytest.fixture
def mock_bedrock_client():
    """Mock AWS Bedrock client"""
    with patch("boto3.client") as mock_client:
        mock_bedrock = MagicMock()
        mock_bedrock.invoke_model.return_value = {
            "body": MagicMock(read=lambda: json.dumps({
                "content": [{"text": "AI-generated summary"}]
            }).encode())
        }
        mock_client.return_value = mock_bedrock
        yield mock_bedrock







