# Módulo de base de datos: una instancia RDS PostgreSQL en las subredes privadas.
#
# - La contraseña del usuario administrador la genera Terraform (random_password,
#   solo letras y números) y se guarda en Secrets Manager. Queda en el state,
#   que está cifrado en S3.
# - Solo se puede llegar a la base desde las tareas de ECS (security group db-sg
#   del módulo security) y no tiene IP pública.

# Contraseña del usuario administrador, generada por Terraform.
# Solo letras y números: catalog lee sus variables con una librería que
# interpreta el símbolo "$" como otra variable y altera la contraseña.

resource "random_password" "master" {
  length  = 32
  special = false
}
 
# Secreto con las credenciales de la base. Mismas claves que el que creaba RDS
# (username y password), así los servicios no cambian.

resource "aws_secretsmanager_secret" "master" {

  name                    = "${var.name}/db"
  description             = "Usuario y contraseña de PostgreSQL (${var.name})"
  recovery_window_in_days = 0
  tags = { Name = "${var.name}/db" }

}
 
resource "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.master.result
  })
}
 
# Grupo de subredes: le dice a RDS en qué subredes (privadas) puede vivir.
# RDS exige subredes en al menos 2 zonas de disponibilidad.

resource "aws_db_subnet_group" "this" {

  name       = "${var.name}-db-subnets"
  subnet_ids = var.subnet_ids
 
  tags = {
    Name = "${var.name}-db-subnets"
  }
}
 
# Grupo de parámetros: configuración del motor PostgreSQL.
# Desde PostgreSQL 15, RDS obliga a usar SSL (rds.force_ssl = 1). Los servicios
# catalog y orders tienen "sslmode=disable" fijo en el código, así que con SSL
# obligatorio no podrían conectarse. Lo apagamos y queda como mejora pasar los
# servicios a sslmode=require y volver a prenderlo.

resource "aws_db_parameter_group" "this" {

  name        = "${var.name}-postgres16"
  family      = "postgres16"
  description = "Parametros de PostgreSQL para ${var.name}"
 
  parameter {

    name  = "rds.force_ssl"
    value = var.force_ssl ? "1" : "0"

  }
 
  tags = {
    Name = "${var.name}-postgres16"
  }
}
 
resource "aws_db_instance" "this" {

  identifier = "${var.name}-db"
 
  # Motor y tamaño

  engine                     = "postgres"

  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage

  storage_type               = "gp3"
  storage_encrypted          = true
  auto_minor_version_upgrade = true
 
  # Base inicial y usuario administrador. La contraseña la genera Terraform (arriba).

  db_name  = var.db_name
  username = var.username
  password = random_password.master.result
 
  # Red: subredes privadas, sin IP pública, solo el security group de la DB

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  port                   = 5432
  parameter_group_name = aws_db_parameter_group.this.name
 
  # Disponibilidad y backups (cambian por ambiente, ver envs/*.tfvars)

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection
 
  # Al destruir: en dev/test no se guarda un snapshot final (Learner Lab).

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-db-final"
 
  # Aplicar los cambios enseguida y no en la próxima ventana de mantenimiento

  apply_immediately = true
 
  # Los logs de PostgreSQL (errores, conexiones rechazadas) van a CloudWatch

  enabled_cloudwatch_logs_exports = ["postgresql"]
 
  # Los snapshots heredan las etiquetas (Project, Environment) de la base

  copy_tags_to_snapshot = true
 
  # Monitoreo extra desactivado: necesita roles de IAM que Learner Lab no deja crear

  performance_insights_enabled = false
  monitoring_interval          = 0
 
  tags = {
    Name = "${var.name}-db"
  }
}