output "rest_api_invoke_url" {
  value = "${aws_api_gateway_deployment.this.invoke_url}"
  description = "Invoke URL for the REST API"
}
