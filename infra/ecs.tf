# Cluster de ECS y lo que comparten todos los servicios.
# =====================================================================
# 1) LabRole: el rol de IAM que ya existe en el Learner Lab
# =====================================================================
# El Learner Lab no deja crear roles de IAM. Usamos el que ya viene,
# LabRole, para que ECS pueda bajar imágenes de ECR, leer secretos de
# Secrets Manager y escribir logs en CloudWatch.

data "aws_iam_role" "lab" {
  name = "LabRole"
}

# =====================================================================
# 2) El cluster
# =====================================================================
# Nota: la idea original era usar Service Connect para que los servicios
# se llamaran por nombre, pero el Learner Lab bloquea Cloud Map
# (servicediscovery:Create*Namespace). La comunicación entre servicios
# pasa por un ALB interno (ver modules/internal-alb).

resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"

  # Container Insights: métricas de CPU, memoria y red por servicio y por tarea
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name}-cluster" }
}