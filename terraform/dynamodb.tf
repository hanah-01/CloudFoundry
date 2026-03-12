resource "aws_dynamodb_table" "artifacts_metadata" {
  name         = "${var.project_name}-artifacts-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "artifact_id"

  attribute {
    name = "artifact_id"
    type = "S"
  }

  # Global Secondary Index to query by environment
  global_secondary_index {
    name            = "environment-index"
    hash_key        = "environment"
    projection_type = "ALL"
  }

  attribute {
    name = "environment"
    type = "S"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-artifacts-metadata"
  })
}
