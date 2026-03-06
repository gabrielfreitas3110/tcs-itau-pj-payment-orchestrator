terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_sqs_queue" "payment_created_dlq" {
  name                      = "${var.payment_created_queue_name}-dlq"
  message_retention_seconds = var.sqs_message_retention_seconds
  tags                      = local.common_tags
}

resource "aws_sqs_queue" "payment_created" {
  name                      = var.payment_created_queue_name
  message_retention_seconds = var.sqs_message_retention_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_created_dlq.arn
    maxReceiveCount     = 5
  })
  tags = local.common_tags
}

resource "aws_sns_topic" "fraud_decision" {
  name = var.fraud_decision_topic_name
  tags = local.common_tags
}

resource "aws_sqs_queue" "notification_dlq" {
  name                      = "${var.notification_queue_name}-dlq"
  message_retention_seconds = var.sqs_message_retention_seconds
  tags                      = local.common_tags
}

resource "aws_sqs_queue" "notification" {
  name                      = var.notification_queue_name
  message_retention_seconds = var.sqs_message_retention_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 5
  })
  tags = local.common_tags
}

resource "aws_sqs_queue_policy" "notification_allow_sns" {
  queue_url = aws_sqs_queue.notification.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowFraudDecisionTopicPublish"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.notification.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.fraud_decision.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "notification_sqs_subscription" {
  topic_arn            = aws_sns_topic.fraud_decision.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.notification.arn
  raw_message_delivery = true
}

resource "aws_dynamodb_table" "fraud_evidence" {
  name         = var.fraud_evidence_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "paymentId"

  attribute {
    name = "paymentId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}
