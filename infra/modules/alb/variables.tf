variable "name" {
  description = "Prefijo para los nombres de los recursos (por ejemplo, tero-dev)."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde viven los target groups."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subredes públicas donde se ubica el ALB (al menos 2 zonas)."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group del ALB (alb-sg del módulo security)."
  type        = string
}

variable "app_port" {
  description = "Puerto en el que escuchan los contenedores de ui y admin."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Ruta que el ALB consulta para saber si un contenedor está sano."
  type        = string
  default     = "/health"
}

variable "admin_paths" {
  description = "Rutas que el ALB envía al servicio admin. El resto va a ui."
  type        = list(string)
  default     = ["/admin", "/admin/*", "/auth/*"]
}