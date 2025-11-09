# Security Module

## Purpose

This module provides security monitoring and alerting capabilities for ChatOps Lambda functions. It provisions:

- **CloudWatch Security Alarms**: DDoS detection, attack monitoring, anomaly detection
- **Enhanced Logging**: Security-focused CloudWatch log groups
- **SNS Notifications**: Real-time alerts for security events
- **Configurable Thresholds**: All alarm thresholds are configurable

## Responsibilities

- Monitor API Gateway request rates for DDoS detection
- Monitor error rates for attack detection
- Monitor Lambda errors and duration
- Detect unusual request patterns (large payloads)
- Monitor API Gateway throttling
- Send alerts via SNS for security events

## Usage

```hcl
module "security" {
  source = "./modules/core/security"

  function_name          = "chatops-webhook-handler"
  api_gateway_name       = "chatops-webhook-api"
  stage_name             = "prod"
  enable_security_alarms = true
  log_retention_days     = 7

  # Optional: Customize alarm thresholds
  high_request_rate_threshold = 100
  high_error_rate_threshold   = 20
  lambda_errors_threshold     = 10

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `function_name` | Name of the Lambda function | `string` | - | yes |
| `api_gateway_name` | Name of the API Gateway | `string` | - | yes |
| `stage_name` | API Gateway stage name | `string` | `"prod"` | no |
| `enable_security_alarms` | Enable security alarms and logging | `bool` | `false` | no |
| `log_retention_days` | CloudWatch log retention (days) | `number` | `7` | no |
| `high_request_rate_threshold` | High request rate threshold (requests/5min) | `number` | `50` | no |
| `high_error_rate_threshold` | High error rate threshold (4XX errors/5min) | `number` | `10` | no |
| `lambda_errors_threshold` | Lambda errors threshold (errors/5min) | `number` | `5` | no |
| `lambda_duration_threshold` | Lambda duration threshold (ms average) | `number` | `25000` | no |
| `large_payloads_threshold` | Large payloads threshold (ms latency) | `number` | `5000` | no |
| `api_throttling_threshold` | API throttling threshold (events/5min) | `number` | `5` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `security_alerts_topic_arn` | ARN of the security alerts SNS topic (if enabled) |
| `security_logs_arn` | ARN of the security logs CloudWatch log group (if enabled) |
| `enhanced_api_logs_arn` | ARN of the enhanced API logs CloudWatch log group (if enabled) |

## Dependencies

### None
This module has no dependencies. It can be used independently for any Lambda function.

## Security Alarms

This module creates the following CloudWatch alarms (when enabled):

### 1. High Request Rate Alarm
- **Metric**: API Gateway request count
- **Threshold**: Configurable (default: 50 requests per 5 minutes)
- **Purpose**: DDoS detection
- **Evaluation**: 2 consecutive periods exceeding threshold

### 2. High Error Rate Alarm
- **Metric**: API Gateway 4XX errors
- **Threshold**: Configurable (default: 10 errors per 5 minutes)
- **Purpose**: Attack detection
- **Evaluation**: 2 consecutive periods exceeding threshold

### 3. Lambda Errors Alarm
- **Metric**: Lambda function errors
- **Threshold**: Configurable (default: 5 errors per 5 minutes)
- **Purpose**: Function failure monitoring
- **Evaluation**: 1 period exceeding threshold

### 4. Lambda Duration Alarm
- **Metric**: Lambda function duration (average)
- **Threshold**: Configurable (default: 25000ms)
- **Purpose**: Timeout attack detection
- **Evaluation**: 2 consecutive periods exceeding threshold

### 5. Large Payloads Alarm
- **Metric**: API Gateway integration latency (average)
- **Threshold**: Configurable (default: 5000ms)
- **Purpose**: Large payload or slow processing detection
- **Evaluation**: 1 period exceeding threshold

### 6. API Throttling Alarm
- **Metric**: API Gateway throttle count
- **Threshold**: Configurable (default: 5 throttles per 5 minutes)
- **Purpose**: Rate limit violation monitoring
- **Evaluation**: 1 period exceeding threshold

## Important Considerations

1. **Conditional Creation**: All resources are conditionally created based on `enable_security_alarms`
2. **Configurable Thresholds**: All alarm thresholds are configurable via variables (defaults provided)
3. **SNS Topic**: Creates SNS topic for alarm notifications (configure subscribers separately)
4. **Log Retention**: Security logs use `log_retention_days` for retention policy
5. **Cost Impact**: Security alarms add ~$3/month (SNS, CloudWatch alarms, log retention)
6. **Custom Thresholds**: Adjust thresholds based on expected traffic patterns
7. **SNS Subscriptions**: Configure SNS topic subscriptions separately (email, SQS, Lambda, etc.)
8. **Evaluation Periods**: Most alarms use 2 evaluation periods to reduce false positives

## Example: With Custom Thresholds

```hcl
module "security" {
  source = "./modules/core/security"

  function_name          = "chatops-webhook-handler"
  api_gateway_name       = "chatops-webhook-api"
  stage_name             = "prod"
  enable_security_alarms = true
  log_retention_days     = 30

  # Custom thresholds for production
  high_request_rate_threshold = 200  # Higher threshold for production
  high_error_rate_threshold   = 25  # More tolerant for expected errors
  lambda_errors_threshold     = 10  # Higher threshold
  lambda_duration_threshold   = 30000  # 30 seconds
  large_payloads_threshold    = 10000  # 10 seconds
  api_throttling_threshold    = 10   # More throttles allowed

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Example: SNS Topic Subscription

After creating the security module, subscribe to the SNS topic:

```hcl
resource "aws_sns_topic_subscription" "security_alerts_email" {
  topic_arn = module.security.security_alerts_topic_arn
  protocol  = "email"
  endpoint  = "security-team@example.com"
}
```

## Cost Impact

When `enable_security_alarms = true`:
- **SNS Topic**: ~$0.50/month (base)
- **CloudWatch Alarms**: ~$0.50/month (6 alarms)
- **CloudWatch Logs**: ~$2/month (log retention)
- **Total**: ~$3/month additional cost

## Related Modules

- **[Webhook Handler Module](../webhook-handler/)** - Typically uses this module
- **[Telegram Bot Module](../../chat/telegram/)** - Can use this module
- **[AI Output Processor Module](../ai-output-processor/)** - Can use this module

