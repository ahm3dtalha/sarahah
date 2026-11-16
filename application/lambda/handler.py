import json
import os

import boto3

table = boto3.resource("dynamodb").Table(os.environ["MESSAGES_TABLE"])

def handler(event, context):
    failures = []
    for record in event["Records"]:
        try:
            body = json.loads(record["body"])
            text = str(body["text"]).strip()[:500]
            if not text:
                raise ValueError("empty message")
            table.put_item(Item={
                "recipient_id": body["recipient_id"],
                "created_at": body["created_at"],
                "text": text,
                "sender_name": str(body.get("sender_name") or "مجهول")[:30],
            })
        except Exception as e:
            print("failed:", record["messageId"], e)
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}