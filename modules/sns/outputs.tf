output "topic_arn" {
  value = aws_sns_topic.shoe_alerts.arn
}

output "publish_policy_arn" {
  value = aws_iam_policy.publish_to_sns.arn
}
