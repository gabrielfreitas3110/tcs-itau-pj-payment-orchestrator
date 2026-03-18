# --------------------------------------------------------------------------- #
# Observability — Sprint 5
# Dashboard, Alarms, X-Ray Group
# --------------------------------------------------------------------------- #

locals {
  cluster_name   = aws_ecs_cluster.main.name
  sfn_arn        = aws_sfn_state_machine.fraud_analysis.arn
  lambda_names = {
    trigger          = aws_lambda_function.fraud_trigger.function_name
    validate_payment = aws_lambda_function.validate_payment.function_name
    score_bedrock    = aws_lambda_function.score_bedrock.function_name
    apply_rules      = aws_lambda_function.apply_rules.function_name
    publish_decision = aws_lambda_function.publish_decision.function_name
  }
}

# --------------------------------------------------------------------------- #
# SNS topic for alarm notifications (subscribe manually via console/email)
# --------------------------------------------------------------------------- #

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"
  tags = local.common_tags
}

# --------------------------------------------------------------------------- #
# CloudWatch Dashboard — PJ Payment Pipeline
# --------------------------------------------------------------------------- #

resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.project_name}-pipeline-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [

      # ------------------------------------------------------------------ #
      # Row 1 — Title
      # ------------------------------------------------------------------ #
      {
        type   = "text"
        x      = 0; y = 0; width = 24; height = 2
        properties = {
          markdown = "# PJ Payment Orchestrator — Pipeline Monitor\n**Ambiente:** ${var.environment} | **Região:** ${var.aws_region}"
        }
      },

      # ------------------------------------------------------------------ #
      # Row 2 — SQS Queue depths
      # ------------------------------------------------------------------ #
      {
        type   = "metric"
        x      = 0; y = 2; width = 8; height = 6
        properties = {
          title  = "SQS — payment-created (backlog)"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible",
              "QueueName", aws_sqs_queue.payment_created.name,
              { stat = "Maximum", label = "Visíveis", color = "#1f77b4" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible",
              "QueueName", aws_sqs_queue.payment_created.name,
              { stat = "Maximum", label = "Em vôo", color = "#aec7e8" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible",
              "QueueName", aws_sqs_queue.payment_created_dlq.name,
              { stat = "Maximum", label = "DLQ", color = "#d62728" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8; y = 2; width = 8; height = 6
        properties = {
          title  = "SQS — payment-settlement"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible",
              "QueueName", aws_sqs_queue.payment_settlement.name,
              { stat = "Maximum", label = "Visíveis", color = "#2ca02c" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible",
              "QueueName", aws_sqs_queue.payment_settlement_dlq.name,
              { stat = "Maximum", label = "DLQ", color = "#d62728" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16; y = 2; width = 8; height = 6
        properties = {
          title  = "SQS — payment-notification"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible",
              "QueueName", aws_sqs_queue.notification.name,
              { stat = "Maximum", label = "Visíveis", color = "#ff7f0e" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible",
              "QueueName", aws_sqs_queue.notification_dlq.name,
              { stat = "Maximum", label = "DLQ", color = "#d62728" }],
          ]
          period = 60
        }
      },

      # ------------------------------------------------------------------ #
      # Row 3 — Step Functions
      # ------------------------------------------------------------------ #
      {
        type   = "metric"
        x      = 0; y = 8; width = 12; height = 6
        properties = {
          title  = "Step Functions — Execuções (fraud-analysis)"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/States", "ExecutionsSucceeded",
              "StateMachineArn", local.sfn_arn,
              { stat = "Sum", label = "Sucesso", color = "#2ca02c" }],
            ["AWS/States", "ExecutionsFailed",
              "StateMachineArn", local.sfn_arn,
              { stat = "Sum", label = "Falha", color = "#d62728" }],
            ["AWS/States", "ExecutionsStarted",
              "StateMachineArn", local.sfn_arn,
              { stat = "Sum", label = "Iniciadas", color = "#1f77b4" }],
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12; y = 8; width = 12; height = 6
        properties = {
          title  = "Step Functions — Duração (ms)"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/States", "ExecutionTime",
              "StateMachineArn", local.sfn_arn,
              { stat = "p50", label = "p50" }],
            ["AWS/States", "ExecutionTime",
              "StateMachineArn", local.sfn_arn,
              { stat = "p95", label = "p95" }],
            ["AWS/States", "ExecutionTime",
              "StateMachineArn", local.sfn_arn,
              { stat = "p99", label = "p99" }],
          ]
          period = 60
        }
      },

      # ------------------------------------------------------------------ #
      # Row 4 — Lambda errors
      # ------------------------------------------------------------------ #
      {
        type   = "metric"
        x      = 0; y = 14; width = 12; height = 6
        properties = {
          title  = "Lambda — Erros por função"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [for k, name in local.lambda_names :
            ["AWS/Lambda", "Errors", "FunctionName", name,
              { stat = "Sum", label = k }]
          ]
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12; y = 14; width = 12; height = 6
        properties = {
          title  = "Lambda — Duração p99 (ms)"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [for k, name in local.lambda_names :
            ["AWS/Lambda", "Duration", "FunctionName", name,
              { stat = "p99", label = k }]
          ]
          period = 60
        }
      },

      # ------------------------------------------------------------------ #
      # Row 5 — ECS running tasks
      # ------------------------------------------------------------------ #
      {
        type   = "metric"
        x      = 0; y = 20; width = 24; height = 6
        properties = {
          title  = "ECS — Tasks em execução por serviço"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount",
              "ClusterName", local.cluster_name,
              "ServiceName", "payment-service",
              { stat = "Average", label = "payment-service", color = "#1f77b4" }],
            ["ECS/ContainerInsights", "RunningTaskCount",
              "ClusterName", local.cluster_name,
              "ServiceName", "settlement-service",
              { stat = "Average", label = "settlement-service", color = "#2ca02c" }],
            ["ECS/ContainerInsights", "RunningTaskCount",
              "ClusterName", local.cluster_name,
              "ServiceName", "notification-service",
              { stat = "Average", label = "notification-service", color = "#ff7f0e" }],
          ]
          period = 60
        }
      },
    ]
  })
}

# --------------------------------------------------------------------------- #
# CloudWatch Alarms — DLQs (qualquer mensagem = incidente)
# --------------------------------------------------------------------------- #

resource "aws_cloudwatch_metric_alarm" "dlq_payment_created" {
  alarm_name          = "${var.project_name}-dlq-payment-created-${var.environment}"
  alarm_description   = "Mensagens na DLQ payment-created — possível falha no pipeline de fraude"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.payment_created_dlq.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_payment_settlement" {
  alarm_name          = "${var.project_name}-dlq-payment-settlement-${var.environment}"
  alarm_description   = "Mensagens na DLQ payment-settlement — settlement-service não está consumindo"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.payment_settlement_dlq.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_payment_notification" {
  alarm_name          = "${var.project_name}-dlq-payment-notification-${var.environment}"
  alarm_description   = "Mensagens na DLQ payment-notification — notification-service não está consumindo"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.notification_dlq.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

# --------------------------------------------------------------------------- #
# CloudWatch Alarms — Step Functions
# --------------------------------------------------------------------------- #

resource "aws_cloudwatch_metric_alarm" "sfn_fraud_failures" {
  alarm_name          = "${var.project_name}-sfn-fraud-failures-${var.environment}"
  alarm_description   = "Step Functions fraud-analysis com falhas nos últimos 5 min"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 2
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = local.sfn_arn
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "sfn_fraud_throttled" {
  alarm_name          = "${var.project_name}-sfn-fraud-throttled-${var.environment}"
  alarm_description   = "Step Functions fraud-analysis com throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionThrottled"
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = local.sfn_arn
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

# --------------------------------------------------------------------------- #
# CloudWatch Alarms — ECS services down
# --------------------------------------------------------------------------- #

resource "aws_cloudwatch_metric_alarm" "ecs_payment_service_down" {
  alarm_name          = "${var.project_name}-ecs-payment-service-down-${var.environment}"
  alarm_description   = "payment-service sem tasks em execução"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "payment-service"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_settlement_service_down" {
  alarm_name          = "${var.project_name}-ecs-settlement-service-down-${var.environment}"
  alarm_description   = "settlement-service sem tasks em execução"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "settlement-service"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_notification_service_down" {
  alarm_name          = "${var.project_name}-ecs-notification-service-down-${var.environment}"
  alarm_description   = "notification-service sem tasks em execução"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = local.cluster_name
    ServiceName = "notification-service"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

# --------------------------------------------------------------------------- #
# Lambda alarms — score_bedrock (mais crítico: chama Bedrock)
# --------------------------------------------------------------------------- #

resource "aws_cloudwatch_metric_alarm" "lambda_score_bedrock_errors" {
  alarm_name          = "${var.project_name}-lambda-score-bedrock-errors-${var.environment}"
  alarm_description   = "Lambda score_bedrock com taxa de erro > 10% nos últimos 5 min"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 3
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "errors / MAX([errors, invocations]) * 100"
    label       = "Erro %"
    return_data = true
  }
  metric_query {
    id = "errors"
    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = 300
      stat        = "Sum"
      dimensions  = { FunctionName = aws_lambda_function.score_bedrock.function_name }
    }
  }
  metric_query {
    id = "invocations"
    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      period      = 300
      stat        = "Sum"
      dimensions  = { FunctionName = aws_lambda_function.score_bedrock.function_name }
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

# --------------------------------------------------------------------------- #
# X-Ray Group — correlação de traces do pipeline
# --------------------------------------------------------------------------- #

resource "aws_xray_group" "pj_payment_pipeline" {
  group_name        = "${var.project_name}-pipeline-${var.environment}"
  filter_expression = "annotation.project = \"${var.project_name}\""

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = true
  }

  tags = local.common_tags
}
