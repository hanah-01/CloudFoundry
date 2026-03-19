resource "aws_cloudwatch_log_group" "artifacts_processor_log" {
  name              = "/aws/lambda/${aws_lambda_function.artifacts_processor.function_name}"
  retention_in_days = 7
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "notifier_log" {
  name              = "/aws/lambda/${aws_lambda_function.notifier.function_name}"
  retention_in_days = 7
  tags              = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "processor_errors" {
  alarm_name          = "${var.project_name}-processor-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This alarm fires if the artifacts processor lambda has errors."
  
  dimensions = {
    FunctionName = aws_lambda_function.artifacts_processor.function_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "notifier_errors" {
  alarm_name          = "${var.project_name}-notifier-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This alarm fires if the notification service lambda has errors."
  
  dimensions = {
    FunctionName = aws_lambda_function.notifier.function_name
  }

  tags = var.common_tags
}