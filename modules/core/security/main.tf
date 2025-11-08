# Shared Security Module
# This module provides security alarms and logging for any Lambda function

# SNS Topic for security alerts
resource "aws_sns_topic" "security_alerts" {
  count = var.enable_security_alarms ? 1 : 0

  name = "${var.function_name}-security-alerts"
  tags = var.tags
}

# SNS Topic Policy for CloudWatch to publish alerts
resource "aws_sns_topic_policy" "security_alerts_policy" {
  count = var.enable_security_alarms ? 1 : 0

  arn = aws_sns_topic.security_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts[0].arn
      }
    ]
  })
}

# Security-focused CloudWatch log group
resource "aws_cloudwatch_log_group" "security_logs" {
  count = var.enable_security_alarms ? 1 : 0

  name              = "/aws/chatops/security/${var.function_name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Purpose = "Security"
    LogType = "SecurityEvents"
  })
}

# Enhanced API Gateway access logging
resource "aws_cloudwatch_log_group" "enhanced_api_logs" {
  count = var.enable_security_alarms ? 1 : 0

  name              = "/aws/apigateway/security/${var.api_gateway_name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Purpose = "Security"
    LogType = "APIGatewaySecurity"
  })
}

# Alarm: High request rate (potential DDoS)
resource "aws_cloudwatch_metric_alarm" "high_request_rate" {
  count = var.enable_security_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-high-request-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "High request rate detected on webhook endpoint"
  alarm_actions       = [aws_sns_topic.security_alerts[0].arn]

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.stage_name
  }

  tags = var.tags
}

# Alarm: High error rate (potential attack)
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  count = var.enable_security_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High error rate detected on webhook endpoint"
  alarm_actions       = [aws_sns_topic.security_alerts[0].arn]

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.stage_name
  }

  tags = var.tags
}

# Alarm: Lambda function errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.enable_security_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High Lambda error rate detected"
  alarm_actions       = [aws_sns_topic.security_alerts[0].arn]

  dimensions = {
    FunctionName = var.function_name
  }

  tags = var.tags
}

# Alarm: Lambda duration (potential timeout attacks)
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count = var.enable_security_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "25000"
  alarm_description   = "Lambda function taking too long to execute"
  alarm_actions       = [aws_sns_topic.security_alerts[0].arn]

  dimensions = {
    FunctionName = var.function_name
  }

  tags = var.tags
}

# Alarm: Unusual request patterns (large payloads)
resource "aws_cloudwatch_metric_alarm" "large_payloads" {
  count = var.enable_security_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-large-payloads"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "IntegrationLatency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"
  alarm_description   = "Large payloads or slow processing detected"
  alarm_actions       = [aws_sns_topic.security_alerts[0].arn]

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.stage_name
  }

  tags = var.tags
}

# Alarm: API Gateway throttling
resource "aws_cloudwatch_metric_alarm" "api_throttling" {
  count = var.enable_security_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-api-throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ThrottleCount"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "API Gateway throttling detected"
  alarm_actions       = [aws_sns_topic.security_alerts[0].arn]

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.stage_name
  }

  tags = var.tags
}
