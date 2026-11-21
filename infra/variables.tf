variable "environment" {
  description = "Nombre del ambiente (dev, test o prod). Tiene que coincidir con el workspace activo."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "El ambiente tiene que ser dev, test o prod."
  }
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC del ambiente."
  type        = string
}

variable "az_count" {
  description = "Cantidad de zonas de disponibilidad."
  type        = number
  default     = 2
}

# ---------- Base de datos (RDS) ----------

variable "db_instance_class" {
  description = "Tamaño de la instancia RDS PostgreSQL."
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Réplica de la base en otra zona de disponibilidad (duplica el costo)."
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Días que se guardan los backups automáticos de la base."
  type        = number
  default     = 1
}

variable "db_deletion_protection" {
  description = "Impide borrar la base (también con terraform destroy) mientras esté activo."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Si es true, al destruir la base no se guarda un snapshot final."
  type        = bool
  default     = true
}

# ---------- Redis (ElastiCache) ----------

variable "redis_node_type" {
  description = "Tamaño del nodo de ElastiCache Redis."
  type        = string
  default     = "cache.t3.micro"
}

# ---------- Servicios (ECS) ----------

variable "image_tag" {
  description = "Tag de las imágenes a desplegar (SHA corto del commit). Si no se pasa, se usa la última imagen publicada en ECR."
  type        = string
  default     = null
}