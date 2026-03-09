# --------------------------------------------------------------------------- #
# Gerais
# --------------------------------------------------------------------------- #

variable "aws_region" {
  description = "Região AWS para todos os recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Identificador do projeto; usado como prefixo nos recursos"
  type        = string
  default     = "pj-payment-orchestrator"
}

variable "environment" {
  description = "Ambiente de deploy (dev, hml, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags adicionais aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

# --------------------------------------------------------------------------- #
# Rede
# --------------------------------------------------------------------------- #

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "developer_cidrs" {
  description = "Lista de CIDRs com acesso ao RDS (ex: seu IP /32 para dev)"
  type        = list(string)
  default     = []
}

# --------------------------------------------------------------------------- #
# SQS
# --------------------------------------------------------------------------- #

variable "payment_created_queue_name" {
  description = "Nome da fila SQS para eventos payment.created"
  type        = string
  default     = "payment-created"
}

variable "fraud_decision_topic_name" {
  description = "Nome do tópico SNS para decisões de fraude"
  type        = string
  default     = "payment-fraud-decision"
}

variable "settlement_queue_name" {
  description = "Nome da fila SQS consumida pelo settlement-service"
  type        = string
  default     = "payment-settlement"
}

variable "notification_queue_name" {
  description = "Nome da fila SQS consumida pelo notification-service"
  type        = string
  default     = "payment-notification"
}

variable "sqs_message_retention_seconds" {
  description = "Tempo de retenção de mensagens SQS (segundos)"
  type        = number
  default     = 345600 # 4 dias
}

# --------------------------------------------------------------------------- #
# DynamoDB
# --------------------------------------------------------------------------- #

variable "fraud_evidence_table_name" {
  description = "Nome da tabela DynamoDB para evidências de fraude"
  type        = string
  default     = "payment-fraud-evidence"
}

# --------------------------------------------------------------------------- #
# RDS — SQL Server (instância existente)
# --------------------------------------------------------------------------- #

variable "db_instance_identifier" {
  description = "Identifier da instância RDS SQL Server já existente"
  type        = string
  default     = "pj-payment-sqlserver-dev"
}

variable "db_username" {
  description = "Usuário master do SQL Server"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Senha master do SQL Server"
  type        = string
  sensitive   = true
}

# --------------------------------------------------------------------------- #
# ECS Fargate
# --------------------------------------------------------------------------- #

variable "ecs_task_cpu" {
  description = "CPU units por task (256 = 0.25 vCPU)"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memória em MiB por task"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Número desejado de tasks por serviço"
  type        = number
  default     = 1
}

# --------------------------------------------------------------------------- #
# Bedrock
# --------------------------------------------------------------------------- #

variable "bedrock_model_id" {
  description = "Model ID do Bedrock para scoring de anomalias"
  type        = string
  default     = "us.anthropic.claude-3-5-haiku-20241022-v1:0"
}
