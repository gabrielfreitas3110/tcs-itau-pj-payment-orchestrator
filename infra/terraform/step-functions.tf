# --------------------------------------------------------------------------- #
# Step Functions — Fraud Analysis Pipeline
# Lambdas: trigger → validate_payment → score_bedrock → apply_rules → publish_decision
# --------------------------------------------------------------------------- #

locals {
  lambda_runtime = "python3.11"
  lambda_prefix  = "${var.project_name}-fraud-sfn-${var.environment}"
  lambdas_root   = "${path.module}/../../lambdas/fraud-step-functions"
}

# --------------------------------------------------------------------------- #
# Lambda source zips (built by Terraform on apply)
# --------------------------------------------------------------------------- #

data "archive_file" "fraud_trigger" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/trigger"
  output_path = "${local.lambdas_root}/trigger.zip"
}

data "archive_file" "validate_payment" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/validate_payment"
  output_path = "${local.lambdas_root}/validate_payment.zip"
}

data "archive_file" "score_bedrock" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/score_bedrock"
  output_path = "${local.lambdas_root}/score_bedrock.zip"
}

data "archive_file" "apply_rules" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/apply_rules"
  output_path = "${local.lambdas_root}/apply_rules.zip"
}

data "archive_file" "publish_decision" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/publish_decision"
  output_path = "${local.lambdas_root}/publish_decision.zip"
}

# --------------------------------------------------------------------------- #
# IAM Role shared by all fraud Lambdas
# --------------------------------------------------------------------------- #

resource "aws_iam_role" "fraud_lambda" {
  name = "${local.lambda_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "fraud_lambda_basic" {
  role       = aws_iam_role.fraud_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "fraud_lambda_app" {
  name = "${local.lambda_prefix}-app-policy"
  role = aws_iam_role.fraud_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSConsume"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = [aws_sqs_queue.payment_created.arn]
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
        Sid    = "StartExecution"
        Effect = "Allow"
        Action = ["states:StartExecution"]
        Resource = [aws_sfn_state_machine.fraud_analysis.arn]
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
        ]
        Resource = ["*"]
      },
    ]
  })
}

# --------------------------------------------------------------------------- #
# IAM Role for Step Functions (invoke Lambdas + CloudWatch Logs)
# --------------------------------------------------------------------------- #

resource "aws_iam_role" "step_functions_fraud" {
  name = "${var.project_name}-fraud-sfn-exec-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "step_functions_fraud_policy" {
  name = "${var.project_name}-sfn-fraud-policy-${var.environment}"
  role = aws_iam_role.step_functions_fraud.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeFraudLambdas"
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          "${aws_lambda_function.validate_payment.arn}:*",
          "${aws_lambda_function.score_bedrock.arn}:*",
          "${aws_lambda_function.apply_rules.arn}:*",
          "${aws_lambda_function.publish_decision.arn}:*",
          aws_lambda_function.validate_payment.arn,
          aws_lambda_function.score_bedrock.arn,
          aws_lambda_function.apply_rules.arn,
          aws_lambda_function.publish_decision.arn,
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
        ]
        Resource = "*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
        ]
        Resource = ["*"]
      },
    ]
  })
}

# --------------------------------------------------------------------------- #
# Lambda Functions
# --------------------------------------------------------------------------- #

resource "aws_lambda_function" "fraud_trigger" {
  function_name    = "${local.lambda_prefix}-trigger"
  role             = aws_iam_role.fraud_lambda.arn
  handler          = "handler.handler"
  runtime          = local.lambda_runtime
  timeout          = 30
  filename         = data.archive_file.fraud_trigger.output_path
  source_code_hash = data.archive_file.fraud_trigger.output_base64sha256

  tracing_config { mode = "Active" }

  environment {
    variables = {
      STATE_MACHINE_ARN = aws_sfn_state_machine.fraud_analysis.arn
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_function" "validate_payment" {
  function_name    = "${local.lambda_prefix}-validate-payment"
  role             = aws_iam_role.fraud_lambda.arn
  handler          = "handler.handler"
  runtime          = local.lambda_runtime
  timeout          = 10
  filename         = data.archive_file.validate_payment.output_path
  source_code_hash = data.archive_file.validate_payment.output_base64sha256

  tracing_config { mode = "Active" }

  tags = local.common_tags
}

resource "aws_lambda_function" "score_bedrock" {
  function_name    = "${local.lambda_prefix}-score-bedrock"
  role             = aws_iam_role.fraud_lambda.arn
  handler          = "handler.handler"
  runtime          = local.lambda_runtime
  timeout          = 60
  filename         = data.archive_file.score_bedrock.output_path
  source_code_hash = data.archive_file.score_bedrock.output_base64sha256

  tracing_config { mode = "Active" }

  environment {
    variables = {
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_function" "apply_rules" {
  function_name    = "${local.lambda_prefix}-apply-rules"
  role             = aws_iam_role.fraud_lambda.arn
  handler          = "handler.handler"
  runtime          = local.lambda_runtime
  timeout          = 10
  filename         = data.archive_file.apply_rules.output_path
  source_code_hash = data.archive_file.apply_rules.output_base64sha256

  tracing_config { mode = "Active" }

  tags = local.common_tags
}

resource "aws_lambda_function" "publish_decision" {
  function_name    = "${local.lambda_prefix}-publish-decision"
  role             = aws_iam_role.fraud_lambda.arn
  handler          = "handler.handler"
  runtime          = local.lambda_runtime
  timeout          = 30
  filename         = data.archive_file.publish_decision.output_path
  source_code_hash = data.archive_file.publish_decision.output_base64sha256

  tracing_config { mode = "Active" }

  environment {
    variables = {
      FRAUD_DECISION_TOPIC_ARN = aws_sns_topic.fraud_decision.arn
      FRAUD_EVIDENCE_TABLE     = aws_dynamodb_table.fraud_evidence.name
      FRAUD_THRESHOLD          = "0.60"
    }
  }

  tags = local.common_tags
}

# --------------------------------------------------------------------------- #
# Step Functions Express Workflow (cheaper for short fraud analysis runs)
# --------------------------------------------------------------------------- #

resource "aws_sfn_state_machine" "fraud_analysis" {
  name     = "${var.project_name}-fraud-analysis-${var.environment}"
  role_arn = aws_iam_role.step_functions_fraud.arn
  type     = "STANDARD"

  tracing_configuration {
    enabled = true
  }

  definition = jsonencode({
    Comment = "PJ Payment — Fraud analysis pipeline"
    StartAt = "ValidatePayment"
    States = {
      ValidatePayment = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "${aws_lambda_function.validate_payment.arn}:$LATEST"
          "Payload.$"  = "$"
        }
        ResultPath = null
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ValidationFailed"
          ResultPath  = "$.error"
        }]
        Next = "ScoreBedrock"
      }

      ScoreBedrock = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "${aws_lambda_function.score_bedrock.arn}:$LATEST"
          "Payload.$"  = "$"
        }
        ResultSelector = { "state.$" = "$.Payload" }
        OutputPath     = "$.state"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        Next = "ApplyRules"
      }

      ApplyRules = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "${aws_lambda_function.apply_rules.arn}:$LATEST"
          "Payload.$"  = "$"
        }
        ResultSelector = { "state.$" = "$.Payload" }
        OutputPath     = "$.state"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        Next = "PublishDecision"
      }

      PublishDecision = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = "${aws_lambda_function.publish_decision.arn}:$LATEST"
          "Payload.$"  = "$"
        }
        ResultPath = null
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts     = 2
          BackoffRate     = 2.0
        }]
        End = true
      }

      ValidationFailed = {
        Type  = "Fail"
        Error = "ValidationFailed"
        Cause = "Payment event failed schema validation"
      }
    }
  })

  tags = local.common_tags
}

# --------------------------------------------------------------------------- #
# SQS Event Source Mapping — triggers fraud_trigger Lambda from payment-created queue
# --------------------------------------------------------------------------- #

resource "aws_lambda_event_source_mapping" "fraud_sqs_trigger" {
  event_source_arn = aws_sqs_queue.payment_created.arn
  function_name    = aws_lambda_function.fraud_trigger.arn
  batch_size       = 1
  enabled          = true
}

# --------------------------------------------------------------------------- #
# CloudWatch Log Groups for Lambda functions (30-day retention)
# --------------------------------------------------------------------------- #

resource "aws_cloudwatch_log_group" "fraud_lambda_logs" {
  for_each = toset([
    "/aws/lambda/${local.lambda_prefix}-trigger",
    "/aws/lambda/${local.lambda_prefix}-validate-payment",
    "/aws/lambda/${local.lambda_prefix}-score-bedrock",
    "/aws/lambda/${local.lambda_prefix}-apply-rules",
    "/aws/lambda/${local.lambda_prefix}-publish-decision",
  ])

  name              = each.value
  retention_in_days = 30
  tags              = local.common_tags
}
