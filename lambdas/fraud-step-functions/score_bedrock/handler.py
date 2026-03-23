import json
import logging
import os
import random

import boto3
from botocore.exceptions import ClientError, NoCredentialsError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

BEDROCK_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "")


def _score_with_bedrock(payment_id: str, amount: float, cnpj: str) -> float:
    prompt = (
        "You are a payment fraud anomaly scoring system. "
        "Given the following transaction, return ONLY a JSON object with a single field 'score' "
        "containing a float between 0.0 (no anomaly) and 1.0 (high anomaly). "
        f"Transaction: payment_id={payment_id}, amount={amount}, cnpj={cnpj}. "
        "Consider high amounts (>10000) and unusual CNPJ patterns as higher risk. "
        'Return only valid JSON, example: {"score": 0.25}'
    )

    region = os.environ.get("AWS_REGION", "us-east-1")
    client = boto3.client("bedrock-runtime", region_name=region)

    response = client.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        body=json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 64,
            "messages": [{"role": "user", "content": prompt}],
        }),
        contentType="application/json",
        accept="application/json",
    )

    body = json.loads(response["body"].read())
    text = body["content"][0]["text"].strip()
    parsed = json.loads(text)
    return max(0.0, min(1.0, float(parsed.get("score", 0.5))))


def _score_deterministic(payment_id: str, amount: float, cnpj: str) -> float:
    seed = hash(f"{payment_id}:{amount}:{cnpj}")
    random.seed(seed)
    return round(random.uniform(0.05, 0.85), 3)


def handler(event, context):
    """
    State: ScoreBedrock
    Queries AWS Bedrock for an AI-based anomaly score.
    Falls back to a deterministic (hash-based) score if Bedrock is unavailable.
    Returns the event enriched with `anomalyScore`.
    """
    payment_id = event["paymentId"]
    amount = event["amount"]
    cnpj = event["cnpj"]

    if BEDROCK_MODEL_ID:
        try:
            score = _score_with_bedrock(payment_id, amount, cnpj)
            logger.info(
                "[ScoreBedrock] paymentId=%s anomalyScore=%.3f (bedrock model=%s)",
                payment_id, score, BEDROCK_MODEL_ID,
            )
        except (ClientError, NoCredentialsError, KeyError, ValueError, json.JSONDecodeError) as e:
            logger.warning("[ScoreBedrock] Bedrock failed, using deterministic. Reason: %s", e)
            score = _score_deterministic(payment_id, amount, cnpj)
    else:
        score = _score_deterministic(payment_id, amount, cnpj)
        logger.info(
            "[ScoreBedrock] paymentId=%s anomalyScore=%.3f (deterministic — BEDROCK_MODEL_ID not set)",
            payment_id, score,
        )

    return {**event, "anomalyScore": score}
