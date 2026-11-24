# ---------- Identificación ----------

variable "name" {
  description = "Nombre del servicio (ui, catalog, carts...)."
  type        = string
}

variable "prefix" {
  description = "Prefijo del ambiente para nombres de recursos (por ejemplo, tero-dev)."
  type        = string
}

variable "cluster_id" {
  description = "ID del cluster de ECS donde corre el servicio."
  type        = string
}

# ---------- Imagen y tamaño ----------

variable "image" {
  description = "Imagen completa con tag (por ejemplo, 5642....dkr.ecr.us-east-1.amazonaws.com/tero/ui:4184fbf)."
  type        = string
}

variable "container_port" {
  description = "Puerto en el que escucha el contenedor."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU de la tarea en unidades de ECS (256 = 0,25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria de la tarea en MB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Cantidad de copias (tareas) del servicio corriendo a la vez."
  type        = number
  default     = 1
}

# ---------- Red ----------

variable "subnet_ids" {
  description = "Subredes donde corren las tareas (públicas: no hay NAT Gateway)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group de las tareas (ecs-sg del módulo security)."
  type        = string
}

# ---------- Permisos ----------

variable "execution_role_arn" {
  description = "Rol que usa ECS para arrancar la tarea: bajar la imagen, leer secretos, escribir logs (LabRole)."
  type        = string
}

variable "task_role_arn" {
  description = "Rol que usa el código del contenedor si llama a servicios de AWS (LabRole)."
  type        = string
}

# ---------- Configuración del contenedor ----------

variable "environment" {
  description = "Variables de entorno comunes (no secretas). Formato: { NOMBRE = \"valor\" }."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Variables de entorno que se leen de Secrets Manager al arrancar. Formato: { NOMBRE = \"arn-del-secreto:clave::\" }."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Días que se guardan los logs en CloudWatch."
  type        = number
  default     = 7
}

# ---------- ALB ----------

variable "target_group_arn" {
  description = "ARN del target group donde se registran las tareas: del ALB público (ui, admin) o del ALB interno (catalog, carts, checkout, orders)."
  type        = string
  default     = null
}