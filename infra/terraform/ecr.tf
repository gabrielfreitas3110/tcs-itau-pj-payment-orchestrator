# --------------------------------------------------------------------------- #
# ECR — um repositório por microsserviço
# --------------------------------------------------------------------------- #

locals {
  ecr_services = toset([
    "payment-service",
    "settlement-service",
    "notification-service",
    "fraud-service",
  ])
}

resource "aws_ecr_repository" "services" {
  for_each             = local.ecr_services
  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, { Service = each.key })
}

resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = local.ecr_services
  repository = aws_ecr_repository.services[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter apenas as últimas 10 imagens"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
