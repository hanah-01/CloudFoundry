terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true   # Required for LocalStack: use path-style S3 URLs

  endpoints {
    ec2         = "http://localhost:4566"
    s3          = "http://localhost:4566"
    iam         = "http://localhost:4566"
    sts         = "http://localhost:4566"
    lambda      = "http://localhost:4566"
    dynamodb    = "http://localhost:4566"
    cloudwatch  = "http://localhost:4566"
    logs        = "http://localhost:4566"
  }

  default_tags {
    tags = var.common_tags
  }
}