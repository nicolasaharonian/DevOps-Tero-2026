output "admin_secret_arn" {
  description = "ARN del secreto del servicio admin. Claves: ADMIN_PASSWORD, ADMIN_JWT_SECRET."
  value       = aws_secretsmanager_secret.admin.arn
}

output "admin_secret_name" {
  description = "Nombre del secreto del servicio admin."
  value       = aws_secretsmanager_secret.admin.name
}
