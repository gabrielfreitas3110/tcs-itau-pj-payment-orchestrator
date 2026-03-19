# --------------------------------------------------------------------------- #
# RDS — referencia a instância SQL Server existente (criada manualmente)
# --------------------------------------------------------------------------- #

data "aws_db_instance" "sqlserver" {
  db_instance_identifier = var.db_instance_identifier
}

# --------------------------------------------------------------------------- #
# SSM Parameter Store — username (não sensível, pode ser String)
# --------------------------------------------------------------------------- #

resource "aws_ssm_parameter" "db_username" {
  name  = "/${var.project_name}/${var.environment}/db/username"
  type  = "String"
  value = var.db_username
  tags  = local.common_tags
}

# --------------------------------------------------------------------------- #
# Secrets Manager — password (suporta rotação automática)
# --------------------------------------------------------------------------- #

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}/${var.environment}/db/password"
  description             = "Senha do RDS SQL Server para o payment orchestrator"
  recovery_window_in_days = 7
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# --------------------------------------------------------------------------- #
# SSM — mantido para compatibilidade (aponta ao mesmo valor)
# --------------------------------------------------------------------------- #

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_password
  tags  = local.common_tags
}
