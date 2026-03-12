# ============================================================
# outputs.tf  –  Expose useful values after apply
# ============================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "web_server_instance_id" {
  description = "EC2 instance ID of the web server"
  value       = length(aws_instance.web_server) > 0 ? aws_instance.web_server[0].id : "EC2 disabled (set create_ec2=true to enable)"
}

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = length(aws_instance.web_server) > 0 ? aws_instance.web_server[0].public_ip : "N/A"
}

output "web_server_public_dns" {
  description = "Public DNS of the web server"
  value       = length(aws_instance.web_server) > 0 ? aws_instance.web_server[0].public_dns : "N/A"
}

output "s3_bucket_name" {
  description = "Name of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "web_sg_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web_server.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB artifacts metadata table"
  value       = aws_dynamodb_table.artifacts_metadata.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB artifacts metadata table"
  value       = aws_dynamodb_table.artifacts_metadata.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda artifacts processor function"
  value       = aws_lambda_function.artifacts_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda artifacts processor function"
  value       = aws_lambda_function.artifacts_processor.arn
}
