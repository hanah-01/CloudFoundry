# ============================================================
# backend.tf  –  Terraform state configuration
#
# LOCAL backend  → default; tfstate stored on disk
# S3 backend     → uncomment when running in CI/CD with a
#                  real (or LocalStack-persisted) S3 bucket
# ============================================================

# ── Active: S3 remote backend (LocalStack) ──────────────────
terraform {
  backend "s3" {
    bucket                      = "devops-lab-tf-state"
    key                         = "devops-lab/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://host.docker.internal:4566"
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    use_path_style              = true
  }
}
