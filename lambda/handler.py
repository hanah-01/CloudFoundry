# pylint: disable=missing-module-docstring
import json
import os
import uuid
from datetime import datetime, timezone

import boto3


def lambda_handler(event, context):
    bucket_name = os.environ.get("BUCKET_NAME", "unknown")
    table_name  = os.environ.get("DYNAMODB_TABLE", "unknown")
    environment = os.environ.get("ENVIRONMENT", "dev")

    print(f"[INFO] Event received: {json.dumps(event)}")
    print(f"[INFO] Bucket={bucket_name}  Table={table_name}  Env={environment}")

    records = event.get("Records", [{"s3": {"object": {"key": "manual-invoke"}}}])
    processed = []

    endpoint = "http://host.docker.internal:4566"
    dynamo = boto3.resource(
        "dynamodb",
        region_name="us-east-1",
        endpoint_url=endpoint,
        aws_access_key_id="test",
        aws_secret_access_key="test",
    )
    table = dynamo.Table(table_name) # pyright: ignore[reportAttributeAccessIssue]

    for record in records:
        key = record.get("s3", {}).get("object", {}).get("key", "unknown")
        item = {
            "artifact_id": str(uuid.uuid4()),
            "environment": environment,
            "bucket": bucket_name,
            "key": key,
            "processed_at": datetime.now(timezone.utc).isoformat(),
        }
        table.put_item(Item=item)
        processed.append(item)
        print(f"[INFO] Stored metadata: {item}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Artifacts processed successfully",
            "processed": processed,
        }),
    }