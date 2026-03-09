import pytest
from pydantic import ValidationError

from app.models import PaymentCreatedEvent, FraudDecisionEvent


class TestPaymentCreatedEvent:

    def test_valid_event_creates_successfully(self):
        event = PaymentCreatedEvent(
            eventId="evt-1",
            eventType="payment.created.v1",
            occurredAt="2026-03-09T10:00:00Z",
            paymentId="pay-1",
            cnpj="12345678000190",
            amount=500.0,
            currency="BRL",
            merchantId="m-1",
        )
        assert event.paymentId == "pay-1"
        assert event.amount == 500.0

    def test_missing_required_field_raises_validation_error(self):
        with pytest.raises(ValidationError):
            PaymentCreatedEvent(
                eventId="evt-1",
                eventType="payment.created.v1",
                occurredAt="2026-03-09T10:00:00Z",
                paymentId="pay-1",
                cnpj="12345678000190",
                # amount missing
                currency="BRL",
                merchantId="m-1",
            )


class TestFraudDecisionEvent:

    def test_approved_decision_is_valid(self):
        event = FraudDecisionEvent(
            eventId="evt-2",
            occurredAt="2026-03-09T10:00:00Z",
            paymentId="pay-2",
            decision="APPROVED",
            ruleScore=0.1,
            anomalyScore=0.05,
            reasons=[],
        )
        assert event.decision == "APPROVED"
        assert event.eventType == "payment.fraud.decision.v1"

    def test_rejected_decision_is_valid(self):
        event = FraudDecisionEvent(
            eventId="evt-3",
            occurredAt="2026-03-09T10:00:00Z",
            paymentId="pay-3",
            decision="REJECTED",
            ruleScore=0.9,
            anomalyScore=0.8,
            reasons=["amount_above_static_limit"],
        )
        assert event.decision == "REJECTED"

    def test_invalid_decision_raises_validation_error(self):
        with pytest.raises(ValidationError):
            FraudDecisionEvent(
                eventId="evt-4",
                occurredAt="2026-03-09T10:00:00Z",
                paymentId="pay-4",
                decision="UNKNOWN",
                ruleScore=0.5,
                anomalyScore=0.5,
                reasons=[],
            )
