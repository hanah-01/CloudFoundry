resource "aws_s3_bucket" "artifacts" {
  bucket        = var.s3_bucket_name
  force_destroy = true   # Allows `terraform destroy` to remove non-empty bucket

  tags = merge(var.common_tags, {
    Name    = var.s3_bucket_name
    Purpose = "artifacts"
  })
}

# -----------------------------------------------------------------
# Block all public access (DevSecOps best practice)
# -----------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------
# Enable versioning so object history is preserved
# -----------------------------------------------------------------
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------
# Server-side encryption – AES-256 (DevSecOps requirement)
# -----------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------
# Lifecycle rule – expire old objects after 90 days (cost control)
# -----------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    filter {
      prefix = "artifacts/"
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
