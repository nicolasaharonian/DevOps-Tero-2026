output "ecr_repository_urls" {
  description = "Dirección de cada repositorio de ECR, por nombre de servicio."
  value       = module.ecr.repository_urls
}

output "ecr_registry_url" {
  description = "Dirección del registro de ECR de la cuenta (para docker login)."
  value       = module.ecr.registry_url
}