resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_policy" {
  name = "${var.function_name}-dynamodb-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for perm in var.dynamodb_permissions : {
        Effect   = "Allow"
        Action   = perm.actions
        Resource = perm.resource
      }
    ]
  })
}

resource "aws_iam_policy" "publish_to_sns" {
  name        = "${var.function_name}-publish-to-sns"
  description = "Allow Lambda to publish to SNS topic"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = var.sns_topic_arn
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_publish_to_sns" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.publish_to_sns.arn
}

resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 10

  filename         = "${path.module}/${var.filename}"
  source_code_hash = filebase64sha256("${path.module}/${var.filename}")

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}
