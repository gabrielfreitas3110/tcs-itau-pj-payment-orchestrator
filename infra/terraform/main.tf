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

resource "aws_sqs_queue" "payment_created" {
  name = "payment-created"
}

resource "aws_sqs_queue" "payment_created_dlq" {
  name = "payment-created-dlq"
}

resource "aws_sns_topic" "fraud_decision" {
  name = "payment-fraud-decision"
}

resource "aws_dynamodb_table" "fraud_evidence" {
  name         = "payment-fraud-evidence"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "paymentId"

  attribute {
    name = "paymentId"
    type = "S"
  }
}
