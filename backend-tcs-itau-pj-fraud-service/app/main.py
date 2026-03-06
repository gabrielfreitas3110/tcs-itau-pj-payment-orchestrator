from datetime import datetime, timezone
from uuid import uuid4
from fastapi import FastAPI
from .models import PaymentCreatedEvent, FraudDecisionEvent
from .rules import evaluate_rules
from .ai_provider import AnomalyScoreProvider
from .repository import FraudEvidenceRepository

app = FastAPI(title="fraud-service")
ai_provider = AnomalyScoreProvider()
evidence_repository = FraudEvidenceRepository()


def _actuator_health() -> dict:
    return {
        "groups": ["liveness", "readiness"],
        "status": "UP",
    }


@app.get("/health")
def health() -> dict:
    return _actuator_health()


@app.get("/actuator/health")
def actuator_health() -> dict:
    return _actuator_health()


@app.post("/events/payment-created", response_model=FraudDecisionEvent)
def process_payment_created(event: PaymentCreatedEvent) -> FraudDecisionEvent:
    rule_score, reasons = evaluate_rules(event)
    anomaly_score = ai_provider.score(event.paymentId, event.amount, event.cnpj)
    total_score = (rule_score * 0.6) + (anomaly_score * 0.4)
    decision = "REJECTED" if total_score >= 0.60 else "APPROVED"

    decision_event = FraudDecisionEvent(
        eventId=str(uuid4()),
        occurredAt=datetime.now(timezone.utc).isoformat(),
        paymentId=event.paymentId,
        decision=decision,
        ruleScore=round(rule_score, 3),
        anomalyScore=round(anomaly_score, 3),
        reasons=reasons if reasons else ["no_rule_triggered"],
    )

    evidence_repository.save_evidence(
        {
            "paymentId": event.paymentId,
            "cnpj": event.cnpj,
            "decisionEventId": decision_event.eventId,
            "decision": decision_event.decision,
            "ruleScore": str(decision_event.ruleScore),
            "anomalyScore": str(decision_event.anomalyScore),
            "reasons": decision_event.reasons,
            "occurredAt": decision_event.occurredAt,
        }
    )

    return decision_event
