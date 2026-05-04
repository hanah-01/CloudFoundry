bucket                      = "devops-lab-tf-state"
key                         = "local/terraform.tfstate"
region                      = "us-east-1"
access_key                  = "test"
secret_key                  = "test"
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
use_path_style              = true

endpoints = {
  s3  = "http://localstack:4566"
  sts = "http://localstack:4566"
  iam = "http://localstack:4566"
}
