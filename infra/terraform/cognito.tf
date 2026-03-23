data "aws_caller_identity" "current" {}

# --------------------------------------------------------------------------- #
# Cognito User Pool
# --------------------------------------------------------------------------- #

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-users-${var.environment}"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  tags = local.common_tags
}

# Domínio do hosted UI (prefixo único por conta)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# --------------------------------------------------------------------------- #
# Resource Server — escopos da API de pagamentos
# --------------------------------------------------------------------------- #

resource "aws_cognito_resource_server" "payment_api" {
  identifier   = "https://api.${var.project_name}.internal"
  name         = "pj-payment-api"
  user_pool_id = aws_cognito_user_pool.main.id

  scope {
    scope_name        = "payments:write"
    scope_description = "Criar e atualizar pagamentos"
  }

  scope {
    scope_name        = "payments:read"
    scope_description = "Consultar pagamentos"
  }
}

# --------------------------------------------------------------------------- #
# App Client — machine-to-machine (client_credentials)
# --------------------------------------------------------------------------- #

resource "aws_cognito_user_pool_client" "payment_service_m2m" {
  name         = "payment-service-m2m"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes = [
    "${aws_cognito_resource_server.payment_api.identifier}/payments:write",
    "${aws_cognito_resource_server.payment_api.identifier}/payments:read",
  ]

  # Client credentials não usam fluxo interativo
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH"]
}

# --------------------------------------------------------------------------- #
# SSM — client_id e client_secret para o payment-service
# --------------------------------------------------------------------------- #

resource "aws_ssm_parameter" "cognito_client_id" {
  name      = "/${var.project_name}/${var.environment}/cognito/client-id"
  type      = "String"
  value     = aws_cognito_user_pool_client.payment_service_m2m.id
  overwrite = true
  tags      = local.common_tags
}

resource "aws_ssm_parameter" "cognito_client_secret" {
  name      = "/${var.project_name}/${var.environment}/cognito/client-secret"
  type      = "SecureString"
  value     = aws_cognito_user_pool_client.payment_service_m2m.client_secret
  overwrite = true
  tags      = local.common_tags
}

resource "aws_ssm_parameter" "cognito_issuer_uri" {
  name      = "/${var.project_name}/${var.environment}/cognito/issuer-uri"
  type      = "String"
  value     = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  overwrite = true
  tags      = local.common_tags
}
