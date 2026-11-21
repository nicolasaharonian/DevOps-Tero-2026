# Módulo de secretos de la aplicación en AWS Secrets Manager.
#
# La contraseña de la base NO está acá: la crea y la guarda RDS (ver módulo
# database). Acá van los secretos propios del servicio admin:
#   - ADMIN_PASSWORD:   contraseña para entrar al panel de administración
#   - ADMIN_JWT_SECRET: clave con la que admin firma los tokens de sesión
#
# Los valores los genera Terraform al azar: nadie los escribe ni los ve, y no
# están en el repositorio. ECS los lee de Secrets Manager al arrancar la tarea.

resource "random_password" "admin_password" {
  length  = 24
  special = false
}

resource "random_password" "admin_jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "admin" {
  # Nombre con el formato aplicacion/ambiente/uso (como en el lab de Secrets Manager)
  name        = "tero/${var.environment}/admin"
  description = "Credenciales y clave JWT del servicio admin (${var.environment})"

  # 0 = se borra enseguida al destruir. Si no, AWS lo guarda 7-30 días
  # "pendiente de borrado" y no deja volver a crear otro con el mismo nombre.
  recovery_window_in_days = var.recovery_window_days

  tags = {
    Name = "tero/${var.environment}/admin"
  }
}

# El contenido del secreto: un JSON con una clave por variable de entorno
resource "aws_secretsmanager_secret_version" "admin" {
  secret_id = aws_secretsmanager_secret.admin.id
  secret_string = jsonencode({
    ADMIN_PASSWORD   = random_password.admin_password.result
    ADMIN_JWT_SECRET = random_password.admin_jwt_secret.result
  })
}
