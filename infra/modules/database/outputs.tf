output "address" {
  description = "Nombre DNS de la base (lo que va en DB_HOST de los servicios)."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Puerto de PostgreSQL."
  value       = aws_db_instance.this.port
}

output "endpoint" {
  description = "Dirección completa de la base, en formato host:puerto."
  value       = "${aws_db_instance.this.address}:${aws_db_instance.this.port}"
}

output "db_name" {
  description = "Base creada al inicio por RDS."
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Usuario administrador de la base."
  value       = aws_db_instance.this.username
}

output "master_secret_arn" {
  description = "ARN del secreto con el usuario y la contraseña de la base. Claves: username, password."
  value       = aws_secretsmanager_secret.master.arn
}
