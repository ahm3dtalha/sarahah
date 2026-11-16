import os
from functools import lru_cache

import boto3

ENDPOINT = os.getenv("AWS_ENDPOINT_URL")        # يوجد على LocalStack فقط
REGION = os.getenv("AWS_REGION", "us-east-1")


def _kw():
    kw = {"region_name": REGION}
    if ENDPOINT:
        kw.update(endpoint_url=ENDPOINT, aws_access_key_id="test", aws_secret_access_key="test")
    return kw


dynamodb = boto3.resource("dynamodb", **_kw())
sqs = boto3.client("sqs", **_kw())

users_table = dynamodb.Table(os.getenv("USERS_TABLE", "sarahah-users"))
messages_table = dynamodb.Table(os.getenv("MESSAGES_TABLE", "sarahah-messages"))


@lru_cache
def queue_url():
    return sqs.get_queue_url(QueueName=os.getenv("QUEUE_NAME", "sarahah-messages"))["QueueUrl"]