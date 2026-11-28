variable "prefix" {
  description = "Prefijo de los nombres (por ejemplo, tero → tero-alertas, tero-notificaciones)."
  type        = string
}

variable "alert_emails" {
  description = "Direcciones de mail que reciben las notificaciones. Cada una tiene que confirmar la suscripción desde el mail que manda AWS."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for e in var.alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Alguna dirección de alert_emails no parece un mail válido."
  }
}

variable "log_retention_days" {
  description = "Días que se guardan los logs de la Lambda en CloudWatch."
  type        = number
  default     = 14
}
