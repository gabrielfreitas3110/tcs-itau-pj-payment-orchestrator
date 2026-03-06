from pydantic import BaseModel, Field
from typing import List


class PaymentCreatedEvent(BaseModel):
    eventId: str
    eventType: str
    occurredAt: str
    paymentId: str
    cnpj: str
    amount: float
    currency: str
    merchantId: str


class FraudDecisionEvent(BaseModel):
    eventId: str
    eventType: str = "payment.fraud.decision.v1"
    occurredAt: str
    paymentId: str
    decision: str = Field(pattern="^(APPROVED|REJECTED)$")
    ruleScore: float
    anomalyScore: float
    reasons: List[str]
