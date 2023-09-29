variable "namespace" {
  default = "namespace"
}

variable "project" {
  default = "project"
}

variable "environment" {
  default = "dev"
}

locals {
  resource_prefix = "${var.namespace}-${var.project}-${var.environment}"
}

resource "aws_s3_bucket" "default" {
  bucket = local.resource_prefix
}

resource "aws_api_gateway_rest_api" "default" {
  name = local.resource_prefix
}

resource "aws_api_gateway_deployment" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.default.id,
      aws_api_gateway_method.default.id,
      aws_api_gateway_integration.default.id
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "default" {
  name = local.resource_prefix
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.default.id
  rest_api_id   = aws_api_gateway_rest_api.default.id
  stage_name    = "prod"
}

resource "aws_api_gateway_resource" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = "open"
}

resource "aws_api_gateway_method" "default" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.default.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "default" {
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.default.id
  http_method             = aws_api_gateway_method.default.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = module.lambda_function.lambda_function_invoke_arn
}

module "lambda_function" {
  source              = "terraform-aws-modules/lambda/aws"
  version             = "~> 6.0"
  timeout             = 300
  source_path         = "../src/app/"
  function_name       = local.resource_prefix
  handler             = "app.handler"
  runtime             = "python3.10"
  create_sam_metadata = true
  publish             = true
  allowed_triggers = {
    APIGatewayAny = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.default.execution_arn}/*/*"
    }
  }
}


