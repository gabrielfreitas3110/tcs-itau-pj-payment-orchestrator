variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier used as prefix in AWS resources"
  type        = string
  default     = "pj-payment-orchestrator"
}

variable "environment" {
  description = "Deployment environment (dev, hml, prod)"
  type        = string
  default     = "dev"
}

variable "payment_created_queue_name" {
  description = "SQS queue name for payment created events"
  type        = string
  default     = "payment-created"
}

variable "fraud_decision_topic_name" {
  description = "SNS topic name for fraud decision events"
  type        = string
  default     = "payment-fraud-decision"
}

variable "notification_queue_name" {
  description = "SQS queue name for notifications"
  type        = string
  default     = "payment-notification"
}

variable "fraud_evidence_table_name" {
  description = "DynamoDB table name for fraud evidence"
  type        = string
  default     = "payment-fraud-evidence"
}

variable "sqs_message_retention_seconds" {
  description = "How long SQS messages are retained"
  type        = number
  default     = 345600
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
