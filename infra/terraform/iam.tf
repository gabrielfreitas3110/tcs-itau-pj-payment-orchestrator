# --------------------------------------------------------------------------- #
# ECS Task Execution Role — pull ECR, injetar SSM/Secrets Manager como env vars
# --------------------------------------------------------------------------- #

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.project_name}-ecs-execution-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Sid      = "DecryptKMS"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      },
    ]
  })
}

# --------------------------------------------------------------------------- #
# Política base reutilizável — CloudWatch Logs + X-Ray (todos os serviços)
# --------------------------------------------------------------------------- #

locals {
  xray_actions = [
    "xray:PutTraceSegments",
    "xray:PutTelemetryRecords",
    "xray:GetSamplingRules",
    "xray:GetSamplingTargets",
  ]
}

# --------------------------------------------------------------------------- #
# payment-service Task Role — apenas produz mensagens para payment-created
# --------------------------------------------------------------------------- #

resource "aws_iam_role" "ecs_task_payment" {
  name = "${var.project_name}-ecs-task-payment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ecs_task_payment" {
  name = "${var.project_name}-ecs-task-payment-policy"
  role = aws_iam_role.ecs_task_payment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSPublishPaymentCreated"
        Effect = "Allow"
        Action = ["sqs:SendMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
        Resource = [
          aws_sqs_queue.payment_created.arn,
          aws_sqs_queue.payment_created_dlq.arn,
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/pj-payment/payment-service:*"]
      },
      {
        Sid      = "XRayTracing"
        Effect   = "Allow"
        Action   = local.xray_actions
        Resource = ["*"]
      },
    ]
  })
}

# --------------------------------------------------------------------------- #
# settlement-service Task Role — apenas consome payment-settlement
# --------------------------------------------------------------------------- #

resource "aws_iam_role" "ecs_task_settlement" {
  name = "${var.project_name}-ecs-task-settlement-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ecs_task_settlement" {
  name = "${var.project_name}-ecs-task-settlement-policy"
  role = aws_iam_role.ecs_task_settlement.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSConsumeSettlement"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
        ]
        Resource = [
          aws_sqs_queue.payment_settlement.arn,
          aws_sqs_queue.payment_settlement_dlq.arn,
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/pj-payment/settlement-service:*"]
      },
      {
        Sid      = "XRayTracing"
        Effect   = "Allow"
        Action   = local.xray_actions
        Resource = ["*"]
      },
    ]
  })
}

# --------------------------------------------------------------------------- #
# notification-service Task Role — apenas consome notification
# --------------------------------------------------------------------------- #

resource "aws_iam_role" "ecs_task_notification" {
  name = "${var.project_name}-ecs-task-notification-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ecs_task_notification" {
  name = "${var.project_name}-ecs-task-notification-policy"
  role = aws_iam_role.ecs_task_notification.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSConsumeNotification"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
        ]
        Resource = [
          aws_sqs_queue.notification.arn,
          aws_sqs_queue.notification_dlq.arn,
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/pj-payment/notification-service:*"]
      },
      {
        Sid      = "XRayTracing"
        Effect   = "Allow"
        Action   = local.xray_actions
        Resource = ["*"]
      },
    ]
  })
}

# --------------------------------------------------------------------------- #
# fraud-service Task Role — role legada para ECS task definition
# (runtime principal é agora Lambda via step-functions.tf)
# --------------------------------------------------------------------------- #

resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ecs_task_app" {
  name = "${var.project_name}-ecs-task-app-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
        ]
        Resource = [
          aws_sqs_queue.payment_created.arn,
          aws_sqs_queue.payment_settlement.arn,
          aws_sqs_queue.notification.arn,
          aws_sqs_queue.payment_created_dlq.arn,
          aws_sqs_queue.payment_settlement_dlq.arn,
          aws_sqs_queue.notification_dlq.arn,
        ]
      },
      {
        Sid      = "SNSPublish"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.fraud_decision.arn]
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Resource = [aws_dynamodb_table.fraud_evidence.arn]
      },
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-*",
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*",
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/pj-payment/*"]
      },
      {
        Sid      = "XRayTracing"
        Effect   = "Allow"
        Action   = local.xray_actions
        Resource = ["*"]
      },
    ]
  })
}
