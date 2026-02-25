# ============================================================
# providers.tf  –  Configure Terraform providers
# LocalStack endpoints override real AWS for local simulation
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------
# AWS Provider – pointed at LocalStack running on localhost:4566
# Credentials are dummy values; LocalStack accepts any key/secret
# -----------------------------------------------------------------
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Route every AWS API call to LocalStack
  endpoints {
    ec2         = "http://localhost:4566"
    s3          = "http://localhost:4566"
    iam         = "http://localhost:4566"
    sts         = "http://localhost:4566"
    lambda      = "http://localhost:4566"
    cloudwatch  = "http://localhost:4566"
    logs        = "http://localhost:4566"
  }
}
