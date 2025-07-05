variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "filename" {
  description = "The name of the ZIP file containing the Lambda code"
  type        = string
}

variable "dynamodb_table_name" {
  description = "The DynamoDB table name to be accessed by Lambda"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table Lambda will access"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for publishing notifications"
  type        = string
}

variable "dynamodb_permissions" {
  description = "List of DynamoDB permissions for the Lambda"
  type = list(object({
    actions  = list(string)
    resource = string
  }))
}
