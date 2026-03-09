# --------------------------------------------------------------------------- #
# ECS Cluster (Fargate)
# --------------------------------------------------------------------------- #

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# --------------------------------------------------------------------------- #
# payment-service (Java/Spring Boot — porta 8080)
# --------------------------------------------------------------------------- #

resource "aws_ecs_task_definition" "payment_service" {
  family                   = "${var.project_name}-payment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "payment-service"
    image = "${aws_ecr_repository.services["payment-service"].repository_url}:latest"
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]

    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "aws,cognito" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "PAYMENT_CREATED_QUEUE", value = aws_sqs_queue.payment_created.name },
      { name = "APP_SECURITY_ENABLED", value = "true" },
      { name = "AWS_SQLSERVER_JDBC_URL", value = "jdbc:sqlserver://${data.aws_db_instance.sqlserver.address}:1433;databaseName=payment_orchestrator;encrypt=true;trustServerCertificate=true" },
      { name = "SPRING_CLOUD_AWS_CREDENTIALS_INSTANCE_PROFILE", value = "true" },
    ]

    secrets = [
      { name = "AWS_SQLSERVER_USERNAME", valueFrom = aws_ssm_parameter.db_username.arn },
      { name = "AWS_SQLSERVER_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
      { name = "COGNITO_CLIENT_ID", valueFrom = aws_ssm_parameter.cognito_client_id.arn },
      { name = "COGNITO_CLIENT_SECRET", valueFrom = aws_ssm_parameter.cognito_client_secret.arn },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/pj-payment/payment-service"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "payment_service" {
  name            = "payment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment_service.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.payment_service.arn
    container_name   = "payment-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
  tags       = local.common_tags
}

# --------------------------------------------------------------------------- #
# fraud-service (Python/FastAPI — porta 8000)
# --------------------------------------------------------------------------- #

resource "aws_ecs_task_definition" "fraud_service" {
  family                   = "${var.project_name}-fraud-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "fraud-service"
    image = "${aws_ecr_repository.services["fraud-service"].repository_url}:latest"
    portMappings = [{ containerPort = 8000, protocol = "tcp" }]

    environment = [
      { name = "AWS_REGION", value = var.aws_region },
      { name = "PAYMENT_CREATED_QUEUE", value = aws_sqs_queue.payment_created.name },
      { name = "FRAUD_DECISION_TOPIC", value = aws_sns_topic.fraud_decision.arn },
      { name = "FRAUD_EVIDENCE_TABLE", value = aws_dynamodb_table.fraud_evidence.name },
      { name = "BEDROCK_MODEL_ID", value = var.bedrock_model_id },
      { name = "AWS_CLOUDWATCH_LOG_GROUP", value = "/pj-payment/fraud-service" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/pj-payment/fraud-service"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "fraud_service" {
  name            = "fraud-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fraud_service.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fraud_service.arn
    container_name   = "fraud-service"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
  tags       = local.common_tags
}

# --------------------------------------------------------------------------- #
# settlement-service (Java/Spring Boot — porta 8082)
# --------------------------------------------------------------------------- #

resource "aws_ecs_task_definition" "settlement_service" {
  family                   = "${var.project_name}-settlement-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "settlement-service"
    image = "${aws_ecr_repository.services["settlement-service"].repository_url}:latest"
    portMappings = [{ containerPort = 8082, protocol = "tcp" }]

    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "SETTLEMENT_QUEUE", value = aws_sqs_queue.payment_settlement.name },
      { name = "AWS_SQLSERVER_JDBC_URL", value = "jdbc:sqlserver://${data.aws_db_instance.sqlserver.address}:1433;databaseName=payment_orchestrator;encrypt=true;trustServerCertificate=true" },
      { name = "SPRING_CLOUD_AWS_CREDENTIALS_INSTANCE_PROFILE", value = "true" },
    ]

    secrets = [
      { name = "AWS_SQLSERVER_USERNAME", valueFrom = aws_ssm_parameter.db_username.arn },
      { name = "AWS_SQLSERVER_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/pj-payment/settlement-service"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "settlement_service" {
  name            = "settlement-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.settlement_service.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.settlement_service.arn
    container_name   = "settlement-service"
    container_port   = 8082
  }

  depends_on = [aws_lb_listener.http]
  tags       = local.common_tags
}

# --------------------------------------------------------------------------- #
# notification-service (Java/Spring Boot — porta 8083)
# --------------------------------------------------------------------------- #

resource "aws_ecs_task_definition" "notification_service" {
  family                   = "${var.project_name}-notification-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "notification-service"
    image = "${aws_ecr_repository.services["notification-service"].repository_url}:latest"
    portMappings = [{ containerPort = 8083, protocol = "tcp" }]

    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "NOTIFICATION_QUEUE", value = aws_sqs_queue.notification.name },
      { name = "SPRING_CLOUD_AWS_CREDENTIALS_INSTANCE_PROFILE", value = "true" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/pj-payment/notification-service"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "notification_service" {
  name            = "notification-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.notification_service.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.notification_service.arn
    container_name   = "notification-service"
    container_port   = 8083
  }

  depends_on = [aws_lb_listener.http]
  tags       = local.common_tags
}
