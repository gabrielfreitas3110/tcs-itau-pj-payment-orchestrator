import json
import logging
import os
import threading

import boto3
from botocore.exceptions import ClientError, NoCredentialsError

logger = logging.getLogger(__name__)


def _build_sqs_client():
    return boto3.client(
        "sqs",
        region_name=os.getenv("AWS_REGION", "us-east-1"),
    )


def _build_sns_client():
    return boto3.client(
        "sns",
        region_name=os.getenv("AWS_REGION", "us-east-1"),
    )


def _get_queue_url(sqs, queue_name: str) -> str | None:
    try:
        response = sqs.get_queue_url(QueueName=queue_name)
        return response["QueueUrl"]
    except (ClientError, NoCredentialsError) as e:
        logger.error("[SQS] Falha ao obter URL da fila '%s': %s", queue_name, e)
        return None


def _publish_fraud_decision(sns, topic_arn: str, decision_event: dict) -> None:
    if not topic_arn:
        logger.warning("[SNS] FRAUD_DECISION_TOPIC nao configurado, pulando publicacao.")
        return
    try:
        sns.publish(
            TopicArn=topic_arn,
            Message=json.dumps(decision_event),
            Subject="payment.fraud.decision.v1",
        )
        logger.info("[SNS] Decisao publicada: paymentId=%s decision=%s",
                    decision_event.get("paymentId"), decision_event.get("decision"))
    except (ClientError, NoCredentialsError) as e:
        logger.error("[SNS] Falha ao publicar decisao: %s", e)


def _poll_loop(process_fn):
    """Background thread that polls SQS and processes payment.created events."""
    queue_name = os.getenv("PAYMENT_CREATED_QUEUE", "payment-created")
    topic_arn  = os.getenv("FRAUD_DECISION_TOPIC", "")

    sqs = _build_sqs_client()
    sns = _build_sns_client()

    queue_url = _get_queue_url(sqs, queue_name)
    if not queue_url:
        logger.error("[SQS] Consumer nao iniciado — fila '%s' nao encontrada.", queue_name)
        return

    logger.info("[SQS] Consumer iniciado. Fila: %s", queue_url)

    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=queue_url,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20,       # long polling — economiza requisicoes
                VisibilityTimeout=60,
            )
            messages = response.get("Messages", [])

            for msg in messages:
                receipt = msg["ReceiptHandle"]
                try:
                    body = json.loads(msg["Body"])

                    # SQS pode encapsular em {"Message": "..."} quando vem do SNS
                    if "Message" in body:
                        body = json.loads(body["Message"])

                    logger.info("[SQS] Processando paymentId=%s", body.get("paymentId"))

                    decision_event = process_fn(body)

                    _publish_fraud_decision(sns, topic_arn, decision_event)

                    sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt)
                    logger.info("[SQS] Mensagem deletada. paymentId=%s decision=%s",
                                body.get("paymentId"), decision_event.get("decision"))

                except Exception as e:
                    logger.error("[SQS] Erro ao processar mensagem: %s", e)
                    # Nao deleta — vai para DLQ apos maxReceiveCount

        except (ClientError, NoCredentialsError) as e:
            logger.error("[SQS] Erro ao receber mensagens: %s", e)
        except Exception as e:
            logger.error("[SQS] Erro inesperado no poll loop: %s", e)


def start_consumer(process_fn):
    """Starts the SQS consumer in a daemon background thread."""
    thread = threading.Thread(target=_poll_loop, args=(process_fn,), daemon=True, name="sqs-consumer")
    thread.start()
    logger.info("[SQS] Thread consumer iniciada.")
