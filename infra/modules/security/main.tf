# =====================================================================
# 1) Security groups (las "cajas" vacías, todavía sin reglas)
# =====================================================================

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB - recibe trafico HTTP desde internet"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-alb-sg" }
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "Tareas ECS - microservicios de Tero"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-ecs-sg" }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "RDS PostgreSQL - solo accesible desde ECS"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-db-sg" }
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "ElastiCache Redis - solo accesible desde ECS"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-redis-sg" }
}

# =====================================================================
# 2) Reglas del ALB
# =====================================================================

# Entrada: cualquiera en internet puede llegar al ALB por el puerto 80
resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP desde internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = var.alb_port
  to_port           = var.alb_port
}

# Salida: el ALB solo puede reenviar trafico a las tareas ECS
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Reenvio hacia los servicios en ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# =====================================================================
# 3) Reglas de ECS
# =====================================================================

# Entrada: el ALB puede llegar a los servicios
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Trafico desde el ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# Entrada: los servicios se pueden llamar entre ellos (ui -> catalog, checkout -> orders...)
resource "aws_vpc_security_group_ingress_rule" "ecs_from_ecs" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Trafico entre microservicios"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# Salida: los servicios pueden salir a cualquier lado
# (bajar imagenes de ECR, leer Secrets Manager, mandar logs, hablar con RDS y Redis)
resource "aws_vpc_security_group_egress_rule" "ecs_all_out" {
  security_group_id = aws_security_group.ecs.id
  description       = "Salida libre (ECR, Secrets Manager, CloudWatch, RDS, Redis)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# =====================================================================
# 4) Reglas de la base de datos y Redis
# =====================================================================

# Entrada: solo las tareas ECS llegan a Postgres
resource "aws_vpc_security_group_ingress_rule" "db_from_ecs" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL desde ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}

# Entrada: solo las tareas ECS llegan a Redis
resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis desde ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = var.redis_port
  to_port                      = var.redis_port
}