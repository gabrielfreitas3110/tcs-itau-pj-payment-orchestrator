output "payment_created_queue_name" {
  description = "SQS queue name consumed by payment-service publisher target"
  value       = aws_sqs_queue.payment_created.name
}

output "payment_created_queue_arn" {
  description = "SQS queue ARN for payment-created events"
  value       = aws_sqs_queue.payment_created.arn
}

output "fraud_decision_topic_arn" {
  description = "SNS topic ARN for fraud decision fan-out"
  value       = aws_sns_topic.fraud_decision.arn
}

output "notification_queue_name" {
  description = "SQS queue name for notification service consumption"
  value       = aws_sqs_queue.notification.name
}

output "notification_queue_arn" {
  description = "SQS queue ARN for notification service consumption"
  value       = aws_sqs_queue.notification.arn
}

output "fraud_evidence_table_name" {
  description = "DynamoDB table storing fraud evidence"
  value       = aws_dynamodb_table.fraud_evidence.name
}
