output "vpc_id" {
  description = "VPC ID"
  value       = module.web_stack.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.web_stack.public_subnet_ids
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = module.web_stack.app_security_group_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = module.web_stack.alb_dns_name
}

output "alb_url" {
  description = "Application URL"
  value       = module.web_stack.alb_url
}

output "single_instance_id" {
  description = "Single instance ID when ASG is disabled"
  value       = module.web_stack.single_instance_id
}

output "s3_bucket_name" {
  description = "Artifacts S3 bucket name"
  value       = module.web_stack.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB artifacts metadata table"
  value       = module.web_stack.dynamodb_table_name
}

output "lambda_function_name" {
  description = "Artifacts processor Lambda name"
  value       = module.web_stack.lambda_function_name
}

output "api_gateway_url" {
  description = "API Gateway endpoint"
  value       = module.web_stack.api_gateway_url
}
