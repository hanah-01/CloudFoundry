terraform {
  backend "s3" {
    bucket                      = "devops-lab-tf-state"
    key                         = "devops-lab/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://host.docker.internal:4566"
    sts_endpoint                = "http://host.docker.internal:4566"
    iam_endpoint                = "http://host.docker.internal:4566"
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
