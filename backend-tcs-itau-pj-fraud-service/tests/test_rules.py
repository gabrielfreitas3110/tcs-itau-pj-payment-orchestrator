from app.models import PaymentCreatedEvent
from app.rules import evaluate_rules


def test_rules_high_amount_triggers():
    event = PaymentCreatedEvent(
        eventId="evt-1",
        eventType="payment.created.v1",
        occurredAt="2026-03-05T10:00:00Z",
        paymentId="pay-1",
        cnpj="12345678000191",
        amount=70000.0,
        currency="BRL",
        merchantId="m1",
    )
    score, reasons = evaluate_rules(event)
    assert score > 0.0
    assert "amount_above_static_limit" in reasons
