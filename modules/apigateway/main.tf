resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "REST API for Shoe Store"
}

resource "aws_api_gateway_resource" "shoes" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "shoes"
}

resource "aws_api_gateway_resource" "shoe_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.shoes.id
  path_part   = "{shoe_id+}"
}

resource "aws_api_gateway_method" "post_shoe" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.shoes.id
  http_method   = "POST"
  authorization = "NONE"
}
# Post - Create Shoe
resource "aws_api_gateway_integration" "create_lambda" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.shoes.id
  http_method = aws_api_gateway_method.post_shoe.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.post_lambda_invoke_arn
}

# GET - Get Shoe
resource "aws_api_gateway_method" "get_shoe" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.shoes.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.shoes.id
  http_method             = aws_api_gateway_method.get_shoe.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.get_lambda_invoke_arn
}


# PUT - Update Shoe
resource "aws_api_gateway_method" "put_shoe" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.shoe_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "update_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.shoe_id.id
  http_method             = aws_api_gateway_method.put_shoe.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.put_lambda_invoke_arn
}

# DELETE - Delete Shoe
resource "aws_api_gateway_method" "delete_shoe" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.shoe_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.shoe_id.id
  http_method             = aws_api_gateway_method.delete_shoe.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.delete_lambda_invoke_arn
}

# SUBSCRIBE - NOTIFICATION 

resource "aws_api_gateway_resource" "subscribe" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "subscribe"
}

resource "aws_api_gateway_method" "subscribe" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.subscribe.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "subscribe_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.subscribe.id
  http_method             = aws_api_gateway_method.subscribe.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.subscribe_lambda_invoke_arn
}


# Deployment and Stage
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.create_lambda,
    aws_api_gateway_integration.get_lambda,
    aws_api_gateway_integration.update_lambda,
    aws_api_gateway_integration.delete_lambda,
    aws_api_gateway_integration.subscribe_lambda
  ]
  rest_api_id = aws_api_gateway_rest_api.this.id
}
resource "aws_api_gateway_stage" "Dev" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "Dev"
}

# Lambda Permissions
resource "aws_lambda_permission" "allow_create" {
  statement_id  = "AllowCreateFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.post_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_get" {
  statement_id  = "AllowGetFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.get_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_update" {
  statement_id  = "AllowUpdateFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.put_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_delete" {
  statement_id  = "AllowDeleteFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.delete_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_subscribe" {
  statement_id  = "AllowSubscribeFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.subscribe_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}