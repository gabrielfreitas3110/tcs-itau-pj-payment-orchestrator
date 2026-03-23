import json
import logging
import os
import uuid

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sfn = boto3.client("stepfunctions")


def handler(event, context):
    """
    Triggered by SQS event source mapping on the payment-created queue.
    Starts one Step Functions Express Workflow execution per message.
    """
    state_machine_arn = os.environ["STATE_MACHINE_ARN"]
    started = []

    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])

            # Unwrap SNS envelope when SQS receives from SNS
            if "Message" in body:
                body = json.loads(body["Message"])

            payment_id = body.get("paymentId", str(uuid.uuid4()))

            # Execution names must be unique and <= 80 chars
            execution_name = f"fraud-{payment_id}"[:80]

            logger.info("[Trigger] Starting execution for paymentId=%s", payment_id)

            sfn.start_execution(
                stateMachineArn=state_machine_arn,
                name=execution_name,
                input=json.dumps(body),
            )

            started.append({"paymentId": payment_id, "status": "started"})

        except sfn.exceptions.ExecutionAlreadyExists:
            # Idempotency: same paymentId received twice — safe to ignore
            logger.warning("[Trigger] Execution already exists for paymentId=%s", payment_id)
            started.append({"paymentId": payment_id, "status": "already_exists"})

        except Exception as e:
            logger.error("[Trigger] Failed to start execution for record: %s", e)
            # Re-raise so the SQS message is NOT deleted (goes to DLQ after maxReceiveCount)
            raise

    logger.info("[Trigger] %d executions started", len(started))
    return {"started": started}
