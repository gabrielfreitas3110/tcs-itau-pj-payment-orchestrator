# --------------------------------------------------------------------------- #
# Mensageria
# --------------------------------------------------------------------------- #

output "payment_created_queue_name" {
  description = "Fila SQS payment-created"
  value       = aws_sqs_queue.payment_created.name
}

output "payment_settlement_queue_name" {
  description = "Fila SQS payment-settlement (consumida pelo settlement-service)"
  value       = aws_sqs_queue.payment_settlement.name
}

output "notification_queue_name" {
  description = "Fila SQS payment-notification"
  value       = aws_sqs_queue.notification.name
}

output "fraud_decision_topic_arn" {
  description = "ARN do tópico SNS de decisões de fraude"
  value       = aws_sns_topic.fraud_decision.arn
}

output "fraud_evidence_table_name" {
  description = "Tabela DynamoDB de evidências de fraude"
  value       = aws_dynamodb_table.fraud_evidence.name
}

# --------------------------------------------------------------------------- #
# Rede
# --------------------------------------------------------------------------- #

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas (ECS)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (RDS)"
  value       = aws_subnet.private[*].id
}

# --------------------------------------------------------------------------- #
# RDS
# --------------------------------------------------------------------------- #

output "rds_endpoint" {
  description = "Endpoint do SQL Server RDS"
  value       = data.aws_db_instance.sqlserver.address
}

output "rds_jdbc_url" {
  description = "JDBC URL pronta para uso nos serviços Java"
  value       = "jdbc:sqlserver://${data.aws_db_instance.sqlserver.address}:1433;databaseName=payment_orchestrator;encrypt=true;trustServerCertificate=true"
}

# --------------------------------------------------------------------------- #
# Cognito
# --------------------------------------------------------------------------- #

output "cognito_user_pool_id" {
  description = "ID do Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_endpoint" {
  description = "Issuer URI do Cognito (usado no Spring Security)"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

output "cognito_token_url" {
  description = "URL para obter token (client_credentials)"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/token"
}

output "cognito_client_id" {
  description = "App Client ID (M2M)"
  value       = aws_cognito_user_pool_client.payment_service_m2m.id
}

# --------------------------------------------------------------------------- #
# ECR
# --------------------------------------------------------------------------- #

output "ecr_repository_urls" {
  description = "URLs dos repositórios ECR por serviço"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

# --------------------------------------------------------------------------- #
# ECS / ALB
# --------------------------------------------------------------------------- #

output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "alb_dns_name" {
  description = "DNS público do ALB (ponto de entrada para todos os serviços)"
  value       = aws_lb.main.dns_name
}

# --------------------------------------------------------------------------- #
# Step Functions / Lambdas
# --------------------------------------------------------------------------- #

output "fraud_state_machine_arn" {
  description = "ARN da Step Functions State Machine de análise de fraude"
  value       = aws_sfn_state_machine.fraud_analysis.arn
}

output "fraud_lambda_trigger_arn" {
  description = "ARN da Lambda trigger (SQS → Step Functions)"
  value       = aws_lambda_function.fraud_trigger.arn
}
