from datetime import datetime, timezone
from .models import PaymentCreatedEvent


def evaluate_rules(event: PaymentCreatedEvent) -> tuple[float, list[str]]:
    reasons = []
    score = 0.0

    if event.amount > 50000:
        score += 0.45
        reasons.append("amount_above_static_limit")

    if int(event.cnpj[-2:]) % 2 == 1:
        score += 0.20
        reasons.append("odd_cnpj_suffix_pattern")

    hour = datetime.now(timezone.utc).hour
    if hour < 5 or hour > 23:
        score += 0.25
        reasons.append("off_hours_transaction")

    if event.currency.upper() != "BRL":
        score += 0.30
        reasons.append("non_brl_transaction")

    return min(score, 1.0), reasons
