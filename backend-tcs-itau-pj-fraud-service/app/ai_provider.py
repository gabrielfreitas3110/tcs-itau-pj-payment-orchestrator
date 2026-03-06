import os
import random


class AnomalyScoreProvider:
    def score(self, payment_id: str, amount: float, cnpj: str) -> float:
        # Placeholder deterministic fallback while Bedrock/SageMaker is not configured.
        model_hint = os.getenv("BEDROCK_MODEL_ID") or os.getenv("SAGEMAKER_ENDPOINT_NAME")
        seed = hash(f"{payment_id}:{amount}:{cnpj}:{model_hint}")
        random.seed(seed)
        return round(random.uniform(0.05, 0.85), 3)
