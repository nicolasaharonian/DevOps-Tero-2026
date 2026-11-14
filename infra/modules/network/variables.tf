variable "name" {
  description = "Prefijo para los nombres de los recursos (por ejemplo, tero-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC (por ejemplo, 10.10.0.0/16)."
  type        = string
}

variable "az_count" {
  description = "Cantidad de zonas de disponibilidad a usar. El ALB y RDS necesitan al menos 2."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "Se necesitan al menos 2 zonas de disponibilidad (requisito del ALB y de RDS)."
  }
}
 