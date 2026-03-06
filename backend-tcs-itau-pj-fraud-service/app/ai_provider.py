import json
import os
import random

import boto3
from botocore.exceptions import ClientError, NoCredentialsError


class AnomalyScoreProvider:
    def score(self, payment_id: str, amount: float, cnpj: str) -> float:
        model_id = os.getenv("BEDROCK_MODEL_ID")
        if model_id:
            return self._score_with_bedrock(model_id, payment_id, amount, cnpj)
        return self._score_deterministic(payment_id, amount, cnpj)

    def _score_with_bedrock(self, model_id: str, payment_id: str, amount: float, cnpj: str) -> float:
        print(f"[Bedrock] Invoking model={model_id} for payment={payment_id} amount={amount}")
        prompt = (
            f"You are a payment fraud anomaly scoring system. "
            f"Given the following transaction, return ONLY a JSON object with a single field 'score' "
            f"containing a float between 0.0 (no anomaly) and 1.0 (high anomaly). "
            f"Transaction: payment_id={payment_id}, amount={amount}, cnpj={cnpj}. "
            f"Consider high amounts (>10000) and unusual CNPJ patterns as higher risk. "
            f"Return only valid JSON, example: {{\"score\": 0.25}}"
        )
        try:
            region = os.getenv("AWS_REGION", "us-east-1")
            client = boto3.client("bedrock-runtime", region_name=region)
            response = client.invoke_model(
                modelId=model_id,
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
            score = float(parsed.get("score", 0.5))
            return max(0.0, min(1.0, score))
        except (ClientError, NoCredentialsError, KeyError, ValueError, json.JSONDecodeError) as e:
            print(f"[Bedrock] Fallback para score deterministico. Motivo: {e}")
            return self._score_deterministic(payment_id, amount, cnpj)

    @staticmethod
    def _score_deterministic(payment_id: str, amount: float, cnpj: str) -> float:
        seed = hash(f"{payment_id}:{amount}:{cnpj}")
        random.seed(seed)
        return round(random.uniform(0.05, 0.85), 3)
