# ============================================================
# backend.tf  –  Terraform state configuration
#
# LOCAL backend  → default; tfstate stored on disk
# S3 backend     → uncomment when running in CI/CD with a
#                  real (or LocalStack-persisted) S3 bucket
# ============================================================

# ── Active: local backend (safe for local development) ──────
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ── Optional: S3 remote backend ─────────────────────────────
# Uncomment the block below (and comment out "local" above)
# to store state in an S3 bucket.  For LocalStack, point the
# endpoint at http://localhost:4566.
#
# terraform {
#   backend "s3" {
#     bucket                      = "devops-lab-tf-state"
#     key                         = "dev/terraform.tfstate"
#     region                      = "us-east-1"
#     endpoint                    = "http://localhost:4566"   # LocalStack
#     access_key                  = "test"
#     secret_key                  = "test"
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     force_path_style            = true
#   }
# }
