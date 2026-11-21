# Módulo ALB: el balanceador que recibe a los usuarios desde internet
# y reparte los pedidos entre ui y admin según la ruta.
# =====================================================================
# 1) El balanceador
# =====================================================================
 
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
 
  # Descarta pedidos con encabezados HTTP mal formados (buena práctica de seguridad)
  drop_invalid_header_fields = true
 
  tags = { Name = "${var.name}-alb" }
}
 
# =====================================================================
# 2) Target groups: a quién se le puede reenviar
# =====================================================================
 
resource "aws_lb_target_group" "ui" {
  name        = "${var.name}-ui-tg"
  vpc_id      = var.vpc_id
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip" # Fargate: cada tarea tiene su propia IP
 
  # Al sacar una tarea vieja, espera 30 s a que termine sus pedidos (por defecto son 300)
  deregistration_delay = 30
 
  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
 
  tags = { Name = "${var.name}-ui-tg" }
}
 
resource "aws_lb_target_group" "admin" {
  name                 = "${var.name}-admin-tg"
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
 
  tags = { Name = "${var.name}-admin-tg" }
}
 
# =====================================================================
# 3) Listener: la puerta 80. Por defecto, todo va a ui
# =====================================================================
 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}
 
# =====================================================================
# 4) Regla: /admin, /admin/* y /auth/* van a admin
# =====================================================================
 
resource "aws_lb_listener_rule" "admin" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
 
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }
 
  condition {
    path_pattern {
      values = var.admin_paths
    }
  }
}