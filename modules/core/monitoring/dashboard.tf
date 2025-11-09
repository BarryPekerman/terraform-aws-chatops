# CloudWatch Dashboard for ChatOps Module
# Provides unified view of all ChatOps resources: Lambdas, API Gateway, Logs, Alarms

locals {
  # Build metrics lists conditionally based on available resources
  # CloudWatch dashboard metrics format: [Namespace, MetricName, DimensionName, DimensionValue, {stat, label}]
  # Format: ["AWS/Lambda", "Invocations", "FunctionName", "function-name", { "stat": "Sum", "label": "Label" }]
  lambda_metrics = concat(
    [
      ["AWS/Lambda", "Invocations", "FunctionName", var.webhook_function_name, { stat = "Sum", label = "Webhook Handler" }],
      ["AWS/Lambda", "Invocations", "FunctionName", var.telegram_function_name, { stat = "Sum", label = "Telegram Bot" }]
    ],
    var.ai_processor_function_name != "" ? [
      ["AWS/Lambda", "Invocations", "FunctionName", var.ai_processor_function_name, { stat = "Sum", label = "AI Processor" }]
    ] : []
  )

  lambda_error_metrics = concat(
    [
      ["AWS/Lambda", "Errors", "FunctionName", var.webhook_function_name, { stat = "Sum", label = "Webhook Handler" }],
      ["AWS/Lambda", "Errors", "FunctionName", var.telegram_function_name, { stat = "Sum", label = "Telegram Bot" }]
    ],
    var.ai_processor_function_name != "" ? [
      ["AWS/Lambda", "Errors", "FunctionName", var.ai_processor_function_name, { stat = "Sum", label = "AI Processor" }]
    ] : []
  )

  lambda_duration_metrics = concat(
    [
      ["AWS/Lambda", "Duration", "FunctionName", var.webhook_function_name, { stat = "Average", label = "Webhook Handler" }],
      ["AWS/Lambda", "Duration", "FunctionName", var.telegram_function_name, { stat = "Average", label = "Telegram Bot" }]
    ],
    var.ai_processor_function_name != "" ? [
      ["AWS/Lambda", "Duration", "FunctionName", var.ai_processor_function_name, { stat = "Average", label = "AI Processor" }]
    ] : []
  )

  lambda_throttle_metrics = concat(
    [
      ["AWS/Lambda", "Throttles", "FunctionName", var.webhook_function_name, { stat = "Sum", label = "Webhook Handler" }],
      ["AWS/Lambda", "Throttles", "FunctionName", var.telegram_function_name, { stat = "Sum", label = "Telegram Bot" }]
    ],
    var.ai_processor_function_name != "" ? [
      ["AWS/Lambda", "Throttles", "FunctionName", var.ai_processor_function_name, { stat = "Sum", label = "AI Processor" }]
    ] : []
  )

  api_metrics = concat(
    [
      ["AWS/ApiGateway", "Count", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Sum", label = "Webhook API" }]
    ],
    var.ai_api_name != "" ? [
      ["AWS/ApiGateway", "Count", "ApiName", var.ai_api_name, "Stage", var.ai_stage_name, { stat = "Sum", label = "AI API" }]
    ] : []
  )

  log_sources = concat(
    [var.webhook_log_group, var.telegram_log_group],
    var.ai_processor_log_group != "" ? [var.ai_processor_log_group] : []
  )
}

resource "aws_cloudwatch_dashboard" "chatops" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = concat(
      # Lambda Metrics Section
      [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          properties = {
            metrics = local.lambda_metrics
            period  = 300
            stat    = "Sum"
            region  = data.aws_region.current.id
            title   = "Lambda Invocations"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 0
          width  = 12
          height = 6
          properties = {
            metrics = local.lambda_error_metrics
            period  = 300
            stat    = "Sum"
            region  = data.aws_region.current.id
            title   = "Lambda Errors"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 6
          width  = 12
          height = 6
          properties = {
            metrics = local.lambda_duration_metrics
            period  = 300
            stat    = "Average"
            region  = data.aws_region.current.id
            title   = "Lambda Duration (ms)"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 6
          width  = 12
          height = 6
          properties = {
            metrics = local.lambda_throttle_metrics
            period  = 300
            stat    = "Sum"
            region  = data.aws_region.current.id
            title   = "Lambda Throttles"
            view    = "timeSeries"
            stacked = false
          }
        }
      ],
      # API Gateway Metrics Section
      [
        {
          type   = "metric"
          x      = 0
          y      = 12
          width  = 12
          height = 6
          properties = {
            metrics = local.api_metrics
            period  = 300
            stat    = "Sum"
            region  = data.aws_region.current.id
            title   = "API Gateway Requests"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 12
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "4XXError", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Sum", label = "4XX Errors" }],
              ["AWS/ApiGateway", "5XXError", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Sum", label = "5XX Errors" }]
            ]
            period  = 300
            stat    = "Sum"
            region  = data.aws_region.current.id
            title   = "API Gateway Errors"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 18
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Latency", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Average", label = "Latency" }],
              ["AWS/ApiGateway", "IntegrationLatency", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Average", label = "Integration Latency" }]
            ]
            period  = 300
            stat    = "Average"
            region  = data.aws_region.current.id
            title   = "API Gateway Latency (ms)"
            view    = "timeSeries"
            stacked = false
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 18
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "ThrottleCount", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Sum", label = "Throttles" }]
            ]
            period  = 300
            stat    = "Sum"
            region  = data.aws_region.current.id
            title   = "API Gateway Throttles"
            view    = "timeSeries"
            stacked = false
          }
        }
      ],
      # CloudWatch Alarms Section (if enabled)
      var.enable_security_alarms ? [
        {
          type   = "metric"
          x      = 0
          y      = 24
          width  = 24
          height = 6
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Count", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Sum", label = "Request Rate" }],
              [".", "4XXError", "ApiName", var.webhook_api_name, "Stage", var.webhook_stage_name, { stat = "Sum", label = "Error Rate" }],
              ["AWS/Lambda", "Errors", "FunctionName", var.webhook_function_name, { stat = "Sum", label = "Lambda Errors" }]
            ]
            period  = 300
            stat    = "Sum"
            region  = data.aws_region.current.id
            title   = "Security Monitoring (5-minute metrics)"
            view    = "timeSeries"
            stacked = false
            annotations = {
              horizontal = [
                {
                  value   = var.high_request_rate_threshold
                  label   = "High Request Rate Threshold"
                  color   = "#ff0000"
                  fill    = "above"
                  visible = true
                },
                {
                  value   = var.high_error_rate_threshold
                  label   = "High Error Rate Threshold"
                  color   = "#ff8800"
                  fill    = "above"
                  visible = true
                }
              ]
            }
          }
        }
      ] : [],
      # Log Groups Links Section
      [
        {
          type   = "log"
          x      = 0
          y      = 30
          width  = 24
          height = 6
          properties = {
            query  = length(local.log_sources) > 0 ? "${join(" | ", [for log_group in local.log_sources : "SOURCE '${log_group}'"])} | fields @timestamp, @message\n| sort @timestamp desc\n| limit 100" : "fields @timestamp, @message\n| sort @timestamp desc\n| limit 100"
            region = data.aws_region.current.id
            title  = "Recent Logs (Last 100 entries)"
            view   = "table"
          }
        }
      ]
    )
  })
}

