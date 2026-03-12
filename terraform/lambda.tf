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
