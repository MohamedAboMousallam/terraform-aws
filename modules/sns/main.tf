resource "aws_sns_topic" "shoe_alerts" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each = var.subscriber_emails

  topic_arn = aws_sns_topic.shoe_alerts.arn
  protocol  = "email"
  endpoint  = each.key

  filter_policy = jsonencode({
    brand = [each.value]
  })
}
resource "aws_iam_policy" "publish_to_sns" {
  name        = "${var.topic_name}-publish-policy"
  description = "IAM policy to allow Lambda to publish to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.shoe_alerts.arn
      }
    ]
  })
}
