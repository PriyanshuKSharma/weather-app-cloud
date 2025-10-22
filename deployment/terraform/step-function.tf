# Step Function for automated deployment
resource "aws_sfn_state_machine" "weather_deploy" {
  name     = "weather-app-deploy"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "Weather App Deployment Pipeline"
    StartAt = "UpdateLambda"
    States = {
      UpdateLambda = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.deploy_function.function_name
          Payload = {
            action = "update_lambda"
          }
        }
        Next = "UpdateS3"
      }
      UpdateS3 = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.deploy_function.function_name
          Payload = {
            action = "update_s3"
          }
        }
        End = true
      }
    }
  })
}

# IAM Role for Step Function
resource "aws_iam_role" "step_function_role" {
  name = "weather-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "weather-step-function-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.deploy_function.arn
      }
    ]
  })
}

# Deployment Lambda Function
resource "aws_lambda_function" "deploy_function" {
  filename         = "deploy-function.zip"
  function_name    = "weather-deploy-function"
  role            = aws_iam_role.deploy_lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 60

  environment {
    variables = {
      SOURCE_BUCKET  = aws_s3_bucket.source_bucket.bucket
      WEBSITE_BUCKET = aws_s3_bucket.website.bucket
      API_URL        = "${aws_apigatewayv2_api.weather_api.api_endpoint}/weather"
    }
  }

  depends_on = [data.archive_file.deploy_zip]
}

data "archive_file" "deploy_zip" {
  type        = "zip"
  output_path = "deploy-function.zip"
  source {
    content = file("../deploy-lambda.js")
    filename = "index.js"
  }
}

# IAM Role for Deploy Lambda
resource "aws_iam_role" "deploy_lambda_role" {
  name = "weather-deploy-lambda-role"

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

resource "aws_iam_role_policy" "deploy_lambda_policy" {
  name = "weather-deploy-lambda-policy"
  role = aws_iam_role.deploy_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge Rule to trigger on file changes
resource "aws_cloudwatch_event_rule" "file_change" {
  name        = "weather-file-change"
  description = "Trigger deployment on file changes"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.source_bucket.bucket]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "step_function" {
  rule      = aws_cloudwatch_event_rule.file_change.name
  target_id = "WeatherDeployTarget"
  arn       = aws_sfn_state_machine.weather_deploy.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# S3 Bucket for source code
resource "aws_s3_bucket" "source_bucket" {
  bucket = "weather-source-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_notification" "source_notification" {
  bucket = aws_s3_bucket.source_bucket.id

  eventbridge = true
}

# IAM Role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "weather-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "weather-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.weather_deploy.arn
      }
    ]
  })
}