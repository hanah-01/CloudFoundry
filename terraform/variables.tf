variable "aws_region" {
  description = "AWS region used by LocalStack"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to every resource"
  type        = string
  default     = "devops-lab"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

# ── VPC / Networking ─────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnet placement"
  type        = string
  default     = "us-east-1a"
}

# ── EC2 ──────────────────────────────────────────────────────
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID (LocalStack accepts any value)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 – placeholder for LocalStack
}

variable "ec2_key_name" {
  description = "EC2 SSH key pair name (optional)"
  type        = string
  default     = ""
}

variable "create_ec2" {
  description = "Set to true to create the EC2 instance. Disabled by default because LocalStack free tier does not support EC2."
  type        = bool
  default     = false
}

variable "localstack_mode" {
  description = "Set to true when running against LocalStack free. Disables features unsupported by LocalStack (lifecycle rules, etc). Set to false for real AWS."
  type        = bool
  default     = true
}

# ── S3 ───────────────────────────────────────────────────────
variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
  default     = "devops-lab-artifacts-bucket"
}

# ── Lambda ───────────────────────────────────────────────────
variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.11"
}

# ── Security ─────────────────────────────────────────────────
variable "admin_ssh_cidr" {
  description = "CIDR allowed to SSH into EC2 instances. Restrict in production."
  type        = string
  default     = "0.0.0.0/0"  # Wide-open for local lab; lock down for real environments
}

# ── Tags ─────────────────────────────────────────────────────
variable "common_tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default = {
    Project     = "devops-lab"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
