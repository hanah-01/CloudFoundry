import json

def lambda_handler(event, context):
    """
    Triggered by DynamoDB Streams whenever a new record is inserted into the
    artifacts_metadata table. Acts as a Mock "Notification Service".
    """
    print("=== NOTIFICATION SERVICE TRIGGERED ===")
    print(f"Received {len(event.get('Records', []))} records from DynamoDB Stream.")

    for record in event.get('Records', []):
        event_name = record.get('eventName')

        if event_name == 'INSERT':
            new_image = record['dynamodb'].get('NewImage', {})
            artifact_id = new_image.get('artifact_id', {}).get('S', 'unknown')
            file_key = new_image.get('key', {}).get('S', 'unknown')
            env = new_image.get('environment', {}).get('S', 'unknown')

            # Simulated Notification (In reality, this could go to SNS, Slack, Discord, or Email)
            print(" ALERT: New artifact uploaded!")
            print(f"   - Environment: {env}")
            print(f"   - File: {file_key}")
            print(f"   - Tracking ID: {artifact_id}")

        elif event_name == 'MODIFY':
            print("INFO: A metadata record was modified.")

        elif event_name == 'REMOVE':
            print("INFO: An artifact record was deleted.")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Stream event processed successfully"})
    }
