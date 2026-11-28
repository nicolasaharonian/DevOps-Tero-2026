variable "alert_emails" {
  description = "Mails del equipo que reciben las notificaciones (alarmas y escaneos de ECR). Se cargan en terraform.tfvars, que no se sube al repo."
  type        = list(string)
  default     = []
}
