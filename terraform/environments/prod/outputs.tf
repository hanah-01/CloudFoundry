output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = module.web_stack.alb_dns_name
}

output "alb_url" {
  description = "HTTP URL for the application"
  value       = module.web_stack.alb_url
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.web_stack.asg_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.web_stack.vpc_id
}

output "api_gateway_url" {
  description = "API Gateway endpoint"
  value       = module.web_stack.api_gateway_url
}
