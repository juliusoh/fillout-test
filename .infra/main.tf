data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "database"
}
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}
/***********************************
AWS Lambda
***********************************/

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  filename         = "artifact.zip"
  function_name    = var.name
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("artifact.zip")
  runtime          = "nodejs18.x"
  architectures    = [local.lambda_arch]
  memory_size      = 256
  timeout          = 30

  environment {
    variables = {
      API_KEY = local.db_creds.fillout_api_key
    }
  }

}

# The REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "FilteredResponsesAPI"
  description = "API for filtered responses"
}

# Resource for /{formId}
resource "aws_api_gateway_resource" "api_formId_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{formId}" # Parameterized part of the URL path
}

# Resource for /{formId}/filteredResponses
resource "aws_api_gateway_resource" "api_filtered_responses_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.api_formId_resource.id
  path_part   = "filteredResponses"
}

# Method for GET /{formId}/filteredResponses
resource "aws_api_gateway_method" "api_filtered_responses_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_filtered_responses_resource.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.limit"          = false
    "method.request.querystring.afterDate"      = false
    "method.request.querystring.beforeDate"     = false
    "method.request.querystring.offset"         = false
    "method.request.querystring.status"         = false
    "method.request.querystring.includeEditLink"= false
    "method.request.querystring.filters"        = false
  }
}

# Integration for GET /{formId}/filteredResponses
resource "aws_api_gateway_integration" "lambda_filtered_responses_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_filtered_responses_resource.id
  http_method = aws_api_gateway_method.api_filtered_responses_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_filtered_responses_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
}

# Lambda permissions
resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/filteredResponses"
}

# Output the base URL for convenience
output "base_url" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}"
}