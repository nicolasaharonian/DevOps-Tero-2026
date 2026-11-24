output "vpc_id" {
  description = "ID de la VPC del ambiente."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas (ALB y tareas de ECS)."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas (base de datos y Redis)."
  value       = module.network.private_subnet_ids
}

output "alb_sg_id" {
  description = "ID del security group del ALB."
  value       = module.security.alb_sg_id
}

output "ecs_sg_id" {
  description = "ID del security group de las tareas ECS."
  value       = module.security.ecs_sg_id
}

output "db_sg_id" {
  description = "ID del security group de RDS PostgreSQL."
  value       = module.security.db_sg_id
}

output "redis_sg_id" {
  description = "ID del security group de ElastiCache Redis."
  value       = module.security.redis_sg_id
}

# ---------- Base de datos ----------

output "db_address" {
  description = "Host de la base PostgreSQL (DB_HOST, CART_POSTGRES_HOST)."
  value       = module.database.address
}

output "db_port" {
  description = "Puerto de la base PostgreSQL."
  value       = module.database.port
}

output "db_endpoint" {
  description = "Host y puerto de la base (RETAIL_CATALOG_PERSISTENCE_ENDPOINT, RETAIL_ORDERS_PERSISTENCE_ENDPOINT)."
  value       = module.database.endpoint
}

output "db_username" {
  description = "Usuario de la base que usan los servicios."
  value       = module.database.username
}

output "db_secret_arn" {
  description = "ARN del secreto de RDS con la contraseña de la base (clave password)."
  value       = module.database.master_secret_arn
}

# ---------- Redis ----------

output "redis_address" {
  description = "Host de ElastiCache Redis."
  value       = module.cache.address
}

output "redis_url" {
  description = "URL de Redis para checkout (RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL)."
  value       = module.cache.url
}

# ---------- Secretos ----------

output "admin_secret_arn" {
  description = "ARN del secreto del servicio admin (claves ADMIN_PASSWORD y ADMIN_JWT_SECRET)."
  value       = module.secrets.admin_secret_arn
}

# ---------- ALB ----------

output "app_url" {
  description = "URL de la tienda."
  value       = module.alb.url
}

output "admin_url" {
  description = "URL del panel de administración."
  value       = "${module.alb.url}/admin"
}

output "image_tag" {
  description = "Versión (SHA corto del commit) desplegada en los servicios."
  value       = local.image_tag
}

# ---------- Inicialización de la base ----------

output "init_db_command" {
  description = "Comando para correr la tarea que inicializa la base (init-db.sql). Se corre una vez cada vez que se crea RDS."

  value = join(" ", [
    "aws ecs run-task",
    "--cluster ${aws_ecs_cluster.this.name}",
    "--launch-type FARGATE",
    "--task-definition ${aws_ecs_task_definition.init_db.family}",
    "--network-configuration awsvpcConfiguration={${join(",", [
      "subnets=[${join(",", module.network.public_subnet_ids)}]",
      "securityGroups=[${module.security.ecs_sg_id}]",
      "assignPublicIp=ENABLED",
    ])}}",
  ])
}