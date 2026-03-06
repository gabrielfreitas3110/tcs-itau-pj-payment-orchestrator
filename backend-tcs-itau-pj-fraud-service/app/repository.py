import os
import boto3
from botocore.exceptions import ClientError


class FraudEvidenceRepository:
    def __init__(self) -> None:
        endpoint = os.getenv("AWS_ENDPOINT")
        region = os.getenv("AWS_REGION", "us-east-1")
        self.table_name = os.getenv("FRAUD_EVIDENCE_TABLE", "payment-fraud-evidence")
        self.client = boto3.resource("dynamodb", endpoint_url=endpoint, region_name=region)

    def save_evidence(self, item: dict) -> None:
        try:
            self.client.Table(self.table_name).put_item(Item=item)
        except ClientError:
            # Keep service resilient in local/dev when table is absent.
            return
