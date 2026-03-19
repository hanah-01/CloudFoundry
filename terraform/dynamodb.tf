resource "aws_dynamodb_table" "artifacts_metadata" {
  name         = "${var.project_name}-artifacts-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "artifact_id"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "artifact_id"
    type = "S"
  }

  global_secondary_index {
    name            = "environment-index"
    hash_key        = "environment"
    projection_type = "ALL"
  }

  attribute {
    name = "environment"
    type = "S"
  }

  ttl {
    attribute_name = "ttl_expiration"
    enabled        = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-artifacts-metadata"
  })
}
