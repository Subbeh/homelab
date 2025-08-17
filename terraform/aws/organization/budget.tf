# SNS Topic for budget notifications
resource "aws_sns_topic" "budget_alerts" {
  name = "budget-alerts"
}

# SNS Topic Policy to allow AWS Budgets to publish
resource "aws_sns_topic_policy" "budget_alerts" {
  arn = aws_sns_topic.budget_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSBudgetsSNSPublishingPermissions"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.budget_alerts.arn
      }
    ]
  })
}

# Organization-wide budget
resource "aws_budgets_budget" "organization" {
  name              = "organization-monthly-budget"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  limit_amount = var.aws_monthly_budget_amount
  limit_unit   = "USD"

  cost_filter {
    name = "LinkedAccount"
    values = [
      module.security_account.account_id,
      module.production_account.account_id,
      module.sandbox_account.account_id
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type           = "PERCENTAGE"
    notification_type        = "ACTUAL"
    subscriber_email_addresses = [var.aws_admin_user_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type           = "PERCENTAGE"
    notification_type        = "ACTUAL"
    subscriber_email_addresses = [var.aws_admin_user_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 90
    threshold_type           = "PERCENTAGE"
    notification_type        = "FORECASTED"
    subscriber_email_addresses = [var.aws_admin_user_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }
} 