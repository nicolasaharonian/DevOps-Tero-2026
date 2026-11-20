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