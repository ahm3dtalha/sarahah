import os
import boto3
from functools import lru_cache

ENDPOINT = os.getenv("AWS_ENDPOINT_URL", "http://localhost:4566")

dynamodb = boto3.resource(
    "dynamodb",
    endpoint_url=ENDPOINT,
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)

users_table = dynamodb.Table("sarahah-users")
messages_table = dynamodb.Table("sarahah-messages")


sqs = boto3.client(
    "sqs",
    endpoint_url=ENDPOINT,
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)


@lru_cache
def queue_url():
    return sqs.get_queue_url(QueueName="sarahah-messages")["QueueUrl"]