import logging
import os
from datetime import datetime, timezone
from uuid import uuid4

import boto3
import watchtower
from dotenv import load_dotenv
from fastapi import FastAPI

from .models import PaymentCreatedEvent, FraudDecisionEvent
from .rules import evaluate_rules
from .ai_provider import AnomalyScoreProvider
from .repository import FraudEvidenceRepository
from .sqs_consumer import start_consumer

load_dotenv(override=True)

# Remove token vazio para não contaminar o boto3 credential chain
if not os.environ.get("AWS_SESSION_TOKEN"):
    os.environ.pop("AWS_SESSION_TOKEN", None)

# Garante que logs da aplicação apareçam no console (além do CloudWatch)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s - %(message)s",
)


def _aws_credentials() -> dict:
    """Credenciais explícitas do .env. session_token=None quando ausente/vazio."""
    return {
        "aws_access_key_id": os.getenv("AWS_ACCESS_KEY_ID"),
        "aws_secret_access_key": os.getenv("AWS_SECRET_ACCESS_KEY"),
        "aws_session_token": os.getenv("AWS_SESSION_TOKEN") or None,
        "region_name": os.getenv("AWS_REGION", "us-east-2"),
    }


def _configure_cloudwatch_logging() -> None:
    """Attach CloudWatch Logs handler when AWS_CLOUDWATCH_LOG_GROUP is set."""
    log_group = os.getenv("AWS_CLOUDWATCH_LOG_GROUP")
    if not log_group:
        return
    try:
        cw_client = boto3.client("logs", **_aws_credentials())
        handler = watchtower.CloudWatchLogHandler(
            log_group=log_group,
            stream_name="fraud-service",
            boto3_client=cw_client,
            create_log_group=False,
        )
        handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s - %(message)s"))
        logging.getLogger().addHandler(handler)
        logging.getLogger().setLevel(logging.INFO)
        logging.getLogger(__name__).info("[CloudWatch] Logging configurado: group=%s", log_group)
    except Exception as exc:
        logging.getLogger(__name__).warning("[CloudWatch] Falha ao configurar logging: %s", exc)


_configure_cloudwatch_logging()

app = FastAPI(title="fraud-service")
ai_provider = AnomalyScoreProvider()
evidence_repository = FraudEvidenceRepository()


def _actuator_health() -> dict:
    return {
        "groups": ["liveness", "readiness"],
        "status": "UP",
    }


@app.on_event("startup")
def on_startup():
    start_consumer(_process_event_dict)


@app.get("/health")
def health() -> dict:
    return _actuator_health()


@app.get("/actuator/health")
def actuator_health() -> dict:
    return _actuator_health()


def _process_event_dict(body: dict) -> dict:
    """Shared logic used by both HTTP endpoint and SQS consumer."""
    event = PaymentCreatedEvent(**body)
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

    evidence_repository.save_evidence({
        "paymentId": event.paymentId,
        "cnpj": event.cnpj,
        "decisionEventId": decision_event.eventId,
        "decision": decision_event.decision,
        "ruleScore": str(decision_event.ruleScore),
        "anomalyScore": str(decision_event.anomalyScore),
        "reasons": decision_event.reasons,
        "occurredAt": decision_event.occurredAt,
    })

    return decision_event.model_dump()


@app.post("/events/payment-created", response_model=FraudDecisionEvent)
def process_payment_created(event: PaymentCreatedEvent) -> FraudDecisionEvent:
    return FraudDecisionEvent(**_process_event_dict(event.model_dump()))
