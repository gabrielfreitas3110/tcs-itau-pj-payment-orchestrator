import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AMOUNT_THRESHOLD = 50_000
AMOUNT_WEIGHT    = 0.45
ODD_CNPJ_WEIGHT  = 0.20
OFF_HOURS_WEIGHT = 0.25
NON_BRL_WEIGHT   = 0.30


def handler(event, context):
    """
    State: ApplyRules
    Applies deterministic business rules to compute a rule-based fraud score.
    Mirrors the logic in the legacy fraud-service rules.py.
    Returns the event enriched with `ruleScore` and `reasons`.
    """
    reasons = []
    score = 0.0

    amount = event["amount"]
    if amount > AMOUNT_THRESHOLD:
        score += AMOUNT_WEIGHT
        reasons.append("amount_above_static_limit")

    cnpj = event["cnpj"]
    try:
        if int(cnpj[-2:]) % 2 == 1:
            score += ODD_CNPJ_WEIGHT
            reasons.append("odd_cnpj_suffix_pattern")
    except (ValueError, IndexError):
        pass

    hour = datetime.now(timezone.utc).hour
    if hour < 5 or hour > 23:
        score += OFF_HOURS_WEIGHT
        reasons.append("off_hours_transaction")

    if event.get("currency", "BRL").upper() != "BRL":
        score += NON_BRL_WEIGHT
        reasons.append("non_brl_transaction")

    rule_score = round(min(score, 1.0), 3)
    final_reasons = reasons if reasons else ["no_rule_triggered"]

    logger.info(
        "[ApplyRules] paymentId=%s ruleScore=%.3f reasons=%s",
        event["paymentId"], rule_score, final_reasons,
    )

    return {**event, "ruleScore": rule_score, "reasons": final_reasons}
