import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REQUIRED_FIELDS = ["paymentId", "cnpj", "amount", "currency", "merchantId"]


def handler(event, context):
    """
    State: ValidatePayment
    Validates required fields and basic constraints on the payment event.
    Returns the event unchanged if valid.
    Raises ValueError on failure — Step Functions catches this and goes to ValidationFailed state.
    """
    missing = [f for f in REQUIRED_FIELDS if not event.get(f)]
    if missing:
        raise ValueError(f"Missing required fields: {missing}")

    amount = event.get("amount")
    if not isinstance(amount, (int, float)) or amount <= 0:
        raise ValueError(f"Invalid amount: {amount!r}")

    cnpj = event.get("cnpj", "")
    if len(cnpj) < 2:
        raise ValueError(f"Invalid CNPJ (too short): {cnpj!r}")

    logger.info(
        "[ValidatePayment] paymentId=%s amount=%.2f currency=%s OK",
        event["paymentId"],
        amount,
        event.get("currency"),
    )

    return event
