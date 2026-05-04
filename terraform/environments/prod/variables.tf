variable "name_prefix" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "devops-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Optional AZ override"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = ""
}

variable "enable_compute" {
  description = "Whether compute resources should be created"
  type        = bool
  default     = true
}

variable "enable_self_healing" {
  description = "Enable ASG based deployment"
  type        = bool
  default     = true
}

variable "enable_load_balancer" {
  description = "Enable ALB and target group"
  type        = bool
  default     = true
}

variable "desired_capacity" {
  description = "ASG desired instance count"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 2
}

variable "alb_ingress_cidr" {
  description = "CIDR allowed to access ALB"
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_ingress_cidr" {
  description = "CIDR allowed to access app directly when ALB is disabled"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_ingress_cidr" {
  description = "Optional CIDR allowed to SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "health_check_path" {
  description = "ALB health check path"
  type        = string
  default     = "/"
}

variable "index_page_content" {
  description = "HTML message written by user_data"
  type        = string
  default     = "Hello from Terraform + Jenkins CI/CD"
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "devops-lab-artifacts-prod-CHANGE-ME"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.11"
}

variable "localstack_mode" {
  description = "True when running against LocalStack"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable CloudWatch log groups and alarms"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default = {
    Project     = "devops-ci-cd"
    Owner       = "jenkins"
    Environment = "prod"
  }
}
