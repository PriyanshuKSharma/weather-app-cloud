terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "weather_api_key" {
  description = "OpenWeatherMap API key"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "S3 bucket name for website hosting"
  type        = string
  default     = ""
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "weather-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function
resource "aws_lambda_function" "weather_function" {
  filename         = "weather-function.zip"
  function_name    = "weather-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"

  environment {
    variables = {
      WEATHER_API_KEY = var.weather_api_key
    }
  }

  depends_on = [data.archive_file.lambda_zip]
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "weather-function.zip"
  source {
    content = file("../lambda/weather-function.js")
    filename = "index.js"
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "weather_api" {
  name          = "weather-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "weather_integration" {
  api_id           = aws_apigatewayv2_api.weather_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.weather_function.invoke_arn
}

resource "aws_apigatewayv2_route" "weather_route" {
  api_id    = aws_apigatewayv2_api.weather_api.id
  route_key = "GET /weather"
  target    = "integrations/${aws_apigatewayv2_integration.weather_integration.id}"
}

resource "aws_apigatewayv2_stage" "weather_stage" {
  api_id      = aws_apigatewayv2_api.weather_api.id
  name        = "$default"
  auto_deploy = true
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.weather_api.execution_arn}/*/*"
}

# S3 Bucket for hosting
resource "aws_s3_bucket" "website" {
  bucket = "weather-app-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Upload index.html with API URL
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = replace(file("../index.html"), "YOUR_API_GATEWAY_URL_HERE", "${aws_apigatewayv2_api.weather_api.api_endpoint}/weather")
  content_type = "text/html"
}

# Outputs
output "api_url" {
  description = "Weather API URL"
  value       = "${aws_apigatewayv2_api.weather_api.api_endpoint}/weather"
}

output "website_url" {
  description = "Website URL"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}