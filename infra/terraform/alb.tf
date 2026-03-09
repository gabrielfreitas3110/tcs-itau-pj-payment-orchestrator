# --------------------------------------------------------------------------- #
# Application Load Balancer
# --------------------------------------------------------------------------- #

resource "aws_lb" "main" {
  name               = "${local.short_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, { Name = "${var.project_name}-alb" })
}

# --------------------------------------------------------------------------- #
# Target Groups
# --------------------------------------------------------------------------- #

resource "aws_lb_target_group" "payment_service" {
  name        = "${local.short_prefix}-payment-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "fraud_service" {
  name        = "${local.short_prefix}-fraud-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "settlement_service" {
  name        = "${local.short_prefix}-settlement-tg"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "notification_service" {
  name        = "${local.short_prefix}-notif-tg"
  port        = 8083
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = local.common_tags
}

# --------------------------------------------------------------------------- #
# Listener HTTP :80 com roteamento por path
# --------------------------------------------------------------------------- #

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default: payment-service
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_service.arn
  }
}

resource "aws_lb_listener_rule" "fraud_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fraud_service.arn
  }

  condition {
    path_pattern { values = ["/events/*", "/health", "/actuator/health", "/docs", "/openapi.json"] }
  }
}

resource "aws_lb_listener_rule" "settlement_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.settlement_service.arn
  }

  condition {
    path_pattern { values = ["/api/v1/settlement/*"] }
  }
}

resource "aws_lb_listener_rule" "notification_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notification_service.arn
  }

  condition {
    path_pattern { values = ["/api/v1/notifications/*"] }
  }
}
