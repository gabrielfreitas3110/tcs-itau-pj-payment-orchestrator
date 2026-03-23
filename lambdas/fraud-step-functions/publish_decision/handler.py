import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FRAUD_DECISION_TOPIC_ARN = os.environ["FRAUD_DECISION_TOPIC_ARN"]
FRAUD_EVIDENCE_TABLE     = os.environ["FRAUD_EVIDENCE_TABLE"]
FRAUD_THRESHOLD          = float(os.environ.get("FRAUD_THRESHOLD", "0.60"))

# Weights match the legacy fraud-service: rules 60%, AI 40%
RULE_WEIGHT    = 0.6
ANOMALY_WEIGHT = 0.4


def handler(event, context):
    """
    State: PublishDecision
    Combines ruleScore (60%) and anomalyScore (40%) to produce a final decision.
    Publishes the decision event to the SNS fraud-decision topic.
    Persists the fraud evidence to DynamoDB (best-effort, does not re-raise on failure).
    """
    payment_id    = event["paymentId"]
    anomaly_score = float(event.get("anomalyScore", 0.5))
    rule_score    = float(event.get("ruleScore", 0.0))
    reasons       = event.get("reasons", ["no_rule_triggered"])

    combined_score = round(RULE_WEIGHT * rule_score + ANOMALY_WEIGHT * anomaly_score, 3)
    decision = "REJECTED" if combined_score >= FRAUD_THRESHOLD else "APPROVED"

    decision_event = {
        "eventId":      str(uuid.uuid4()),
        "eventType":    "payment.fraud.decision.v1",
        "occurredAt":   datetime.now(timezone.utc).isoformat(),
        "paymentId":    payment_id,
        "decision":     decision,
        "ruleScore":    rule_score,
        "anomalyScore": anomaly_score,
        "reasons":      reasons,
    }

    logger.info(
        "[PublishDecision] paymentId=%s decision=%s combinedScore=%.3f (rule=%.3f anomaly=%.3f)",
        payment_id, decision, combined_score, rule_score, anomaly_score,
    )

    region = os.environ.get("AWS_REGION", "us-east-1")
    sns      = boto3.client("sns",      region_name=region)
    dynamodb = boto3.resource("dynamodb", region_name=region)

    # Publish to SNS — critical path, raise on failure
    try:
        sns.publish(
            TopicArn=FRAUD_DECISION_TOPIC_ARN,
            Message=json.dumps(decision_event),
            Subject="payment.fraud.decision.v1",
        )
        logger.info("[PublishDecision] SNS published for paymentId=%s", payment_id)
    except ClientError as e:
        logger.error("[PublishDecision] SNS publish failed: %s", e)
        raise

    # Save evidence to DynamoDB — best-effort, do not fail the execution
    try:
        table = dynamodb.Table(FRAUD_EVIDENCE_TABLE)
        table.put_item(Item={
            "paymentId":       payment_id,
            "cnpj":            event.get("cnpj", ""),
            "decisionEventId": decision_event["eventId"],
            "decision":        decision,
            "ruleScore":       str(rule_score),
            "anomalyScore":    str(anomaly_score),
            "reasons":         reasons,
            "occurredAt":      decision_event["occurredAt"],
            # TTL: keep evidence for 90 days
            "ttl": int(datetime.now(timezone.utc).timestamp()) + 90 * 24 * 3600,
        })
        logger.info("[PublishDecision] DynamoDB saved for paymentId=%s", payment_id)
    except ClientError as e:
        logger.error("[PublishDecision] DynamoDB save failed (non-fatal): %s", e)

    return decision_event
