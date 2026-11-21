# Módulo ALB interno: reparte el tráfico entre microservicios según la ruta.
# Reemplaza a Service Connect, que el Learner Lab no permite (Cloud Map bloqueado).
# Solo es accesible desde dentro de la VPC.

# =====================================================================
# 1) El balanceador (interno)
# =====================================================================

resource "aws_lb" "this" {
  name                       = "${var.name}-int-alb"
  load_balancer_type         = "application"
  internal                   = true # sin dirección pública: solo se llega desde la VPC
  security_groups            = [var.security_group_id]
  subnets                    = var.subnet_ids
  drop_invalid_header_fields = true
  tags                       = { Name = "${var.name}-int-alb" }
}

# =====================================================================
# 2) Un target group por servicio (catalog, carts, checkout, orders)
# =====================================================================

resource "aws_lb_target_group" "this" {
  for_each = var.services

  name                 = "${var.name}-${each.key}-tg"
  vpc_id               = var.vpc_id
  port                 = var.app_port
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "${var.name}-${each.key}-tg" }
}

# =====================================================================
# 3) Listener: puerto 80. Si la ruta no es de ningún servicio, responde 404
# =====================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Ruta no encontrada"
      status_code  = "404"
    }
  }
}

# =====================================================================
# 4) Una regla por servicio: /catalog* → catalog, /carts* → carts...
# =====================================================================

resource "aws_lb_listener_rule" "this" {
  for_each = var.services

  listener_arn = aws_lb_listener.http.arn
  priority     = 10 + index(keys(var.services), each.key) * 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value
    }
  }
}