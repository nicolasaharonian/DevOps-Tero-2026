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