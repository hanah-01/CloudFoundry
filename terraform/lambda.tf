data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/handler.py"
  output_path = "${path.module}/../lambda/handler.zip"
}

# IAM role that Lambda assumes at runtime
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

# Basic execution policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

# Inline policy to allow Lambda to access S3 and DynamoDB
resource "aws_iam_role_policy" "lambda_s3_dynamo" {
  name = "${var.project_name}-lambda-s3-dynamo-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan"]
        Resource = aws_dynamodb_table.artifacts_metadata.arn
      }
    ]
  })
}

# Lambda function – processes S3 artifact events and logs to DynamoDB
resource "aws_lambda_function" "artifacts_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-artifacts-processor"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = var.lambda_runtime
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      BUCKET_NAME    = aws_s3_bucket.artifacts.id
      DYNAMODB_TABLE = aws_dynamodb_table.artifacts_metadata.name
      ENVIRONMENT    = var.environment
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-artifacts-processor"
  })
}

# Allow S3 to invoke this Lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.artifacts_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.artifacts.arn
}

# S3 bucket notification – trigger Lambda on every object upload
resource "aws_s3_bucket_notification" "artifacts_trigger" {
  bucket = aws_s3_bucket.artifacts.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.artifacts_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "artifacts/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# NOTIFICATION SERVICE (Second Lambda triggered by DynamoDB Streams)
# matches the "Notification Service" & "State Handlers" 

data "archive_file" "notifier_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/notifier.py"
  output_path = "${path.module}/../lambda/notifier.zip"
}

resource "aws_iam_role" "notifier_exec" {
  name = "${var.project_name}-notifier-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "notifier_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.notifier_exec.name
}

# The Notifier Lambda strictly requires DynamoDB Stream read permissions
resource "aws_iam_role_policy" "notifier_stream_policy" {
  name = "${var.project_name}-notifier-stream-policy"
  role = aws_iam_role.notifier_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams"
      ]
      Effect   = "Allow"
      Resource = aws_dynamodb_table.artifacts_metadata.stream_arn
    }]
  })
}

resource "aws_lambda_function" "notifier" {
  filename         = data.archive_file.notifier_zip.output_path
  function_name    = "${var.project_name}-notification-service"
  role             = aws_iam_role.notifier_exec.arn
  handler          = "notifier.lambda_handler"
  runtime          = var.lambda_runtime
  source_code_hash = data.archive_file.notifier_zip.output_base64sha256
  timeout          = 30

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-notification-service"
  })
}

# The glue connecting DynamoDB Streams -> The Notification Lambda
resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  event_source_arn  = aws_dynamodb_table.artifacts_metadata.stream_arn
  function_name     = aws_lambda_function.notifier.arn
  starting_position = "LATEST"
}
