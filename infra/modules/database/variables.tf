variable "name" {
  description = "Prefijo para los nombres de los recursos (por ejemplo, tero-dev)."
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas donde vive la base (al menos 2 zonas)."
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group de la base (db-sg del módulo security)."
  type        = string
}

variable "engine_version" {
  description = "Versión de PostgreSQL. Con solo la versión mayor, AWS elige la última menor."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "Tamaño de la instancia RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Disco de la base en GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Base que RDS crea al inicio. Las demás (catalogdb, cartdb) las crea init-db.sql."
  type        = string
  default     = "orders"
}

variable "username" {
  description = "Usuario administrador de la base (el mismo que usan los servicios)."
  type        = string
  default     = "retail_user"
}

variable "multi_az" {
  description = "Si es true, RDS mantiene una réplica en otra zona y cambia sola si la principal falla."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Días que se guardan los backups automáticos (0 los desactiva)."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Si es true, AWS no deja borrar la base hasta desactivarlo."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Si es true, al destruir la base no se guarda un snapshot final."
  type        = bool
  default     = true
}

variable "force_ssl" {
  description = "Obliga a los clientes a conectarse con SSL (rds.force_ssl)."
  type        = bool
  default     = false
}
