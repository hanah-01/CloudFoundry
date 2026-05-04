output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = var.enable_load_balancer ? aws_lb.app[0].dns_name : null
}

output "alb_url" {
  description = "Application URL"
  value = var.enable_load_balancer ? "http://${aws_lb.app[0].dns_name}" : (
    var.enable_compute && !var.enable_self_healing ? "http://${aws_instance.single[0].public_ip}" : null
  )
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = var.enable_compute && var.enable_self_healing ? aws_autoscaling_group.app[0].name : null
}

output "single_instance_id" {
  description = "Single instance ID when ASG is disabled"
  value       = var.enable_compute && !var.enable_self_healing ? aws_instance.single[0].id : null
}

output "s3_bucket_name" {
  description = "Artifacts S3 bucket name"
  value       = aws_s3_bucket.artifacts.bucket
}

output "s3_bucket_arn" {
  description = "Artifacts S3 bucket ARN"
  value       = aws_s3_bucket.artifacts.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB artifacts metadata table"
  value       = aws_dynamodb_table.artifacts_metadata.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB artifacts metadata table ARN"
  value       = aws_dynamodb_table.artifacts_metadata.arn
}

output "lambda_function_name" {
  description = "Artifacts processor Lambda name"
  value       = aws_lambda_function.artifacts_processor.function_name
}

output "lambda_function_arn" {
  description = "Artifacts processor Lambda ARN"
  value       = aws_lambda_function.artifacts_processor.arn
}

output "notifier_function_name" {
  description = "Notification Lambda name"
  value       = aws_lambda_function.notifier.function_name
}

output "api_gateway_url" {
  description = "API Gateway endpoint"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/process"
}
