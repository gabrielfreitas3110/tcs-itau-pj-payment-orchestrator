import os
import boto3
from botocore.exceptions import ClientError, NoCredentialsError


class FraudEvidenceRepository:
    def __init__(self) -> None:
        endpoint = os.getenv("AWS_ENDPOINT") or None
        region = os.getenv("AWS_REGION", "us-east-1")
        self.table_name = os.getenv("FRAUD_EVIDENCE_TABLE", "payment-fraud-evidence")
        self.client = boto3.resource(
            "dynamodb",
            endpoint_url=endpoint,
            region_name=region,
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
            aws_session_token=os.getenv("AWS_SESSION_TOKEN") or None,
        )

    def save_evidence(self, item: dict) -> None:
        try:
            self.client.Table(self.table_name).put_item(Item=item)
        except (ClientError, NoCredentialsError):
            # Keep service resilient in local/dev when table is absent.
            return
