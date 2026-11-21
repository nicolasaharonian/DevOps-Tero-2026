variable "name" {
  description = "Prefijo para los nombres de los recursos (por ejemplo, tero-dev)."
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde viven los target groups."
  type        = string
}

variable "subnet_ids" {
  description = "Subredes privadas donde se ubica el ALB interno (al menos 2 zonas)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group del ALB interno (internal-alb-sg del módulo security)."
  type        = string
}

variable "app_port" {
  description = "Puerto en el que escuchan los contenedores."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Ruta que el ALB consulta para saber si un contenedor está sano."
  type        = string
  default     = "/health"
}

variable "services" {
  description = "Servicios internos y las rutas que atiende cada uno (salen del código: cada servicio responde bajo su propio prefijo)."
  type        = map(list(string))
  default = {
    catalog  = ["/catalog", "/catalog/*"]
    carts    = ["/carts", "/carts/*"]
    checkout = ["/checkout", "/checkout/*"]
    orders   = ["/orders", "/orders/*"]
  }
}