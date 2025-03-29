variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "CloudStruct" {
  name              = "/ecs/${var.project_name}-${var.environment}-${var.repository_name}"
  retention_in_days = var.log_retention_days
  
  tags = var.default_tags
}

# CloudWatch Log Group for Cluster
resource "aws_cloudwatch_log_group" "cluster_logs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_days
  
  tags = var.default_tags
}

# CloudWatch Logs policy for Lambda
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for WAF Logs 
resource "aws_cloudwatch_log_group" "waf_logs" {
  # Simplified name without extra path segments
  name              = "aws-waf-logs-${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  
  tags = var.default_tags
}

# CloudWatch Dashboard for WAF metrics (optional)
resource "aws_cloudwatch_dashboard" "waf_dashboard" {
  count = var.waf_enabled ? 1 : 0
  
  dashboard_name = "${var.project_name}-${var.environment}-waf-dashboard"
  
  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/WAFV2", "BlockedRequests", "WebACL", "${aws_wafv2_web_acl.main.name}", "Region", "${var.aws_region}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.aws_region}",
        "title": "Blocked Requests",
        "period": 300,
        "stat": "Sum"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/WAFV2", "AllowedRequests", "WebACL", "${aws_wafv2_web_acl.main.name}", "Region", "${var.aws_region}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.aws_region}",
        "title": "Allowed Requests",
        "period": 300,
        "stat": "Sum"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 24,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/WAFV2", "CountedRequests", "WebACL", "${aws_wafv2_web_acl.main.name}", "Rule", "RateLimitRule", "Region", "${var.aws_region}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.aws_region}",
        "title": "Rate Limited Requests",
        "period": 60,
        "stat": "Sum"
      }
    }
  ]
}
EOF
  # CloudWatch Dashboard does not support tags in any provider version
}

# CloudWatch Alarm for high rate of blocked requests
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  count               = var.waf_enabled ? 1 : 0
  
  alarm_name          = "${var.project_name}-${var.environment}-waf-high-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "This alarm triggers when the WAF blocks more than 100 requests in a 5-minute period"
  
  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = var.aws_region
  }
  
  tags = var.default_tags  # AWS Provider 5.0 fully supports tags for metric alarms
}