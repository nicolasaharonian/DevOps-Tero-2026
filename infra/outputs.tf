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
 