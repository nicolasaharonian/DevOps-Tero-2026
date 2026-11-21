# Módulo ecs-service: el molde de un microservicio en ECS Fargate.
# Crea el grupo de logs, la "receta" del contenedor (task definition)
# y el servicio que lo mantiene corriendo.

data "aws_region" "current" {}

locals {
  full_name = "${var.prefix}-${var.name}" # por ejemplo, tero-dev-catalog
}

# =====================================================================
# 1) Grupo de logs en CloudWatch
# =====================================================================

resource "aws_cloudwatch_log_group" "this" {

  name              = "/ecs/${var.prefix}/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = { Name = "/ecs/${var.prefix}/${var.name}" }
}

# =====================================================================
# 2) Task definition: la "receta" del contenedor
# =====================================================================

resource "aws_ecs_task_definition" "this" {

  family                   = local.full_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {

    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"

  }

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true
      portMappings = [

        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      # Convierte { NOMBRE = "valor" } al formato que pide ECS
      environment = [for k, v in var.environment : { name = k, value = v }]
      secrets     = [for k, v in var.secrets : { name = k, valueFrom = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])

  tags = { Name = local.full_name }

}

# =====================================================================
# 3) El servicio: mantiene el contenedor siempre corriendo
# =====================================================================

resource "aws_ecs_service" "this" {

  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {

    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true # sin NAT, la IP pública es lo que le permite bajar la imagen de ECR

  }

  # 4) Si recibió un target group, se anota en esa lista del ALB (público o interno)

  dynamic "load_balancer" {

    for_each = var.target_group_arn == null ? [] : [var.target_group_arn]

    content {

      target_group_arn = load_balancer.value
      container_name   = var.name
      container_port   = var.container_port

    }

  }

  # Tiempo de gracia para que arranque antes de que el ALB lo juzgue
  health_check_grace_period_seconds = var.target_group_arn == null ? null : 60

  # Deploy sin cortes: primero prende la tarea nueva y después apaga la vieja
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # Si la versión nueva no arranca, vuelve sola a la anterior
  deployment_circuit_breaker {

    enable   = true
    rollback = true

  }

  propagate_tags = "SERVICE"
  tags           = { Name = local.full_name }

}
 