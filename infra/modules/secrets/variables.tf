variable "environment" {
  description = "Nombre del ambiente (dev, test o prod). Se usa en el nombre del secreto."
  type        = string
}

variable "recovery_window_days" {
  description = "Días que AWS guarda un secreto borrado antes de eliminarlo (0 = inmediato)."
  type        = number
  default     = 0
}
