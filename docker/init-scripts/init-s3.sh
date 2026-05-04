#!/usr/bin/env bash
set -euo pipefail

echo "Initializing LocalStack resources..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create S3 bucket
awslocal s3 mb s3://test-bucket 2>/dev/null || echo "test-bucket already exists"

# Upload test file
if [ -f "${SCRIPT_DIR}/test.txt" ]; then
  awslocal s3 cp "${SCRIPT_DIR}/test.txt" s3://test-bucket/test.txt
else
  echo "Hello LocalStack" | awslocal s3 cp - s3://test-bucket/test.txt
fi

# List buckets to verify
echo "S3 Buckets:"
awslocal s3 ls

echo "LocalStack initialization complete!"