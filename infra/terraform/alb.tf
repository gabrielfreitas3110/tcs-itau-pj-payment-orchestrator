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
# Listener :80  →  payment-service (default)
# --------------------------------------------------------------------------- #

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_service.arn
  }
}

# --------------------------------------------------------------------------- #
# Listener :8000  →  fraud-service
# --------------------------------------------------------------------------- #

resource "aws_lb_listener" "fraud_service" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fraud_service.arn
  }
}

# --------------------------------------------------------------------------- #
# Listener :8082  →  settlement-service
# --------------------------------------------------------------------------- #

resource "aws_lb_listener" "settlement_service" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8082
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.settlement_service.arn
  }
}

# --------------------------------------------------------------------------- #
# Listener :8083  →  notification-service
# --------------------------------------------------------------------------- #

resource "aws_lb_listener" "notification_service" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8083
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notification_service.arn
  }
}
