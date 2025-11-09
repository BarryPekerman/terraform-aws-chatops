# CloudWatch Dashboard Module

## Purpose

This module creates a comprehensive CloudWatch Dashboard for monitoring all ChatOps resources. It provides a unified view of:

- **Lambda Metrics**: Invocations, errors, duration, throttles for all Lambda functions
- **API Gateway Metrics**: Requests, errors, latency, throttles for all API Gateways
- **Security Alarms**: Visual thresholds and alarm status (if enabled)
- **Log Groups**: Direct links to CloudWatch log groups
- **X-Ray Traces**: Links to service map and traces (if enabled)

## Responsibilities

- Aggregate metrics from all ChatOps Lambda functions
- Aggregate metrics from all ChatOps API Gateways
- Display security alarm thresholds and status
- Provide log group links for troubleshooting
- Create unified monitoring dashboard

## Usage

```hcl
module "monitoring" {
  source = "./modules/core/monitoring"

  dashboard_name = "chatops-dashboard"

  webhook_function_name = module.webhook_handler.lambda_function_name
  telegram_function_name = module.telegram_bot.bot_function_name
  ai_processor_function_name = module.ai_processor.processor_function_name  # Optional

  webhook_api_name = "chatops-webhook-api"
  webhook_stage_name = "prod"
  ai_api_name = "chatops-ai-api"  # Optional
  ai_stage_name = "prod"

  webhook_log_group = "/aws/lambda/${module.webhook_handler.lambda_function_name}"
  telegram_log_group = "/aws/lambda/${module.telegram_bot.bot_function_name}"
  ai_processor_log_group = "/aws/lambda/${module.ai_processor.processor_function_name}"  # Optional

  enable_security_alarms = true
  high_request_rate_threshold = 50
  high_error_rate_threshold = 10

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `dashboard_name` | Name of the CloudWatch dashboard | `string` | - | yes |
| `webhook_function_name` | Name of webhook handler Lambda | `string` | - | yes |
| `telegram_function_name` | Name of Telegram bot Lambda | `string` | - | yes |
| `ai_processor_function_name` | Name of AI processor Lambda | `string` | `""` | no |
| `webhook_api_name` | Name of webhook API Gateway | `string` | - | yes |
| `webhook_stage_name` | Stage name of webhook API | `string` | `"prod"` | no |
| `ai_api_name` | Name of AI processor API Gateway | `string` | `""` | no |
| `ai_stage_name` | Stage name of AI processor API | `string` | `"prod"` | no |
| `webhook_log_group` | CloudWatch log group for webhook handler | `string` | - | yes |
| `telegram_log_group` | CloudWatch log group for Telegram bot | `string` | - | yes |
| `ai_processor_log_group` | CloudWatch log group for AI processor | `string` | `""` | no |
| `enable_security_alarms` | Enable security alarm widgets | `bool` | `false` | no |
| `high_request_rate_threshold` | High request rate threshold | `number` | `50` | no |
| `high_error_rate_threshold` | High error rate threshold | `number` | `10` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `dashboard_url` | URL to the CloudWatch dashboard |
| `dashboard_arn` | ARN of the CloudWatch dashboard |

## Dashboard Widgets

### Lambda Metrics (4 widgets)
1. **Invocations**: Total invocations per Lambda function
2. **Errors**: Total errors per Lambda function
3. **Duration**: Average duration per Lambda function (ms)
4. **Throttles**: Total throttles per Lambda function

### API Gateway Metrics (4 widgets)
1. **Requests**: Total requests per API Gateway
2. **Errors**: 4XX and 5XX errors per API Gateway
3. **Latency**: Average latency and integration latency (ms)
4. **Throttles**: Total throttles per API Gateway

### Security Monitoring (1 widget, if enabled)
- **Security Metrics**: Request rate, error rate, Lambda errors with threshold annotations

### Logs (1 widget)
- **Recent Logs**: Last 100 log entries from all log groups (table view)

## Important Considerations

1. **Automatic Metrics**: Lambda and API Gateway metrics are automatically collected by AWS
2. **Optional Resources**: AI processor and AI API are optional - dashboard handles missing resources
3. **Log Groups**: Log groups must exist before dashboard creation (created by Lambda modules)
4. **Dashboard Limits**: CloudWatch dashboards support up to 100 widgets
5. **Cost**: CloudWatch dashboards are free - only pay for metrics and logs
6. **Refresh Rate**: Dashboard refreshes automatically every few minutes
7. **Customization**: Dashboard JSON can be customized for specific needs

## Example: Without AI Processor

```hcl
module "monitoring" {
  source = "./modules/core/monitoring"

  dashboard_name = "chatops-dashboard"

  webhook_function_name = module.webhook_handler.lambda_function_name
  telegram_function_name = module.telegram_bot.bot_function_name
  # AI processor omitted

  webhook_api_name = "chatops-webhook-api"
  webhook_stage_name = "prod"
  # AI API omitted

  webhook_log_group = "/aws/lambda/${module.webhook_handler.lambda_function_name}"
  telegram_log_group = "/aws/lambda/${module.telegram_bot.bot_function_name}"
  # AI processor log group omitted

  enable_security_alarms = true

  tags = {
    Environment = "production"
  }
}
```

## Accessing the Dashboard

After creation, access the dashboard via:
1. **AWS Console**: CloudWatch → Dashboards → Select dashboard name
2. **Direct URL**: Use `dashboard_url` output value
3. **CLI**: `aws cloudwatch get-dashboard --dashboard-name chatops-dashboard`

## Related Modules

- **[Webhook Handler Module](../webhook-handler/)** - Provides Lambda function name and log group
- **[Telegram Bot Module](../../chat/telegram/)** - Provides Lambda function name and log group
- **[AI Output Processor Module](../ai-output-processor/)** - Provides Lambda function name and log group (optional)
- **[Security Module](../security/)** - Provides alarm thresholds (optional)

## Cost

**CloudWatch Dashboard**: Free (no additional cost)

**What You Pay For**:
- CloudWatch Metrics: First 1M metrics free, then $0.30 per 1M metrics
- CloudWatch Logs: $0.50/GB ingestion + $0.03/GB storage
- CloudWatch Alarms: $0.10 per alarm per month

**Typical Monthly Cost**: $0-5/month (depending on usage)

