# --------------------------------------------------------------------------- #
# RDS — referencia a instância SQL Server existente (criada manualmente)
# --------------------------------------------------------------------------- #

data "aws_db_instance" "sqlserver" {
  db_instance_identifier = var.db_instance_identifier
}

# --------------------------------------------------------------------------- #
# SSM Parameter Store — credenciais do RDS
# --------------------------------------------------------------------------- #

resource "aws_ssm_parameter" "db_username" {
  name      = "/${var.project_name}/${var.environment}/db/username"
  type      = "String"
  value     = var.db_username
  overwrite = true
  tags      = local.common_tags
}

resource "aws_ssm_parameter" "db_password" {
  name      = "/${var.project_name}/${var.environment}/db/password"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
  tags      = local.common_tags
}
