variable "topic_name" {
  type        = string
  description = "Name of the SNS topic"
  default     = "shoe-alerts-topic"
}

variable "subscriber_emails" {
  description = "Map of subscriber email addresses and their preferred shoe brand"
  type        = map(string)
  default = {
    "mohamedaaymn33@gmail.com" = "Nike",
  }
}
