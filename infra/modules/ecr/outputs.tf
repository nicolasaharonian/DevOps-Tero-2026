output "repository_urls" {
  description = "Dirección de cada repositorio, por nombre de servicio (para docker push y para ECS)."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}
 
output "registry_url" {
  description = "Dirección del registro de ECR de la cuenta (para docker login)."
  value       = split("/", values(aws_ecr_repository.this)[0].repository_url)[0]
}