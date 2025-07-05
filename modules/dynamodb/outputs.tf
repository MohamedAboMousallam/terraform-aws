output "shoe_table_name" {
  value = aws_dynamodb_table.shoe_table.name
}

output "user_table_name" {
  value       = aws_dynamodb_table.user_table.name
}

output "shoe_table_arn" {
  value = aws_dynamodb_table.shoe_table.arn
}

output "user_table_arn" {
  value = aws_dynamodb_table.user_table.arn
}