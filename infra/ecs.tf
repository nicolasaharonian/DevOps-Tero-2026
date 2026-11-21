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
# 2) Namespace de Service Connect: la "guía telefónica" interna
# =====================================================================
# Permite que los servicios se llamen por nombre (http://catalog:8080),
# igual que en docker compose.
 
resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name
  description = "Service Connect de ${local.name}: los servicios se llaman por nombre"
 
  tags = { Name = local.name }
}
 
# =====================================================================
# 3) El cluster
# =====================================================================
 
resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"
 
  # Container Insights: métricas de CPU, memoria y red por servicio y por tarea
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
 
  # Todos los servicios del cluster usan este namespace por defecto
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.this.arn
  }
 
  tags = { Name = "${local.name}-cluster" }
}