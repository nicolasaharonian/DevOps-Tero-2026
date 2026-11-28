# ---------- Identificación ----------

variable "name" {
  description = "Prefijo del ambiente para nombres de recursos (por ejemplo, tero-dev)."
  type        = string
}

variable "region" {
  description = "Región de AWS (los widgets del dashboard la necesitan)."
  type        = string
}

# ---------- Qué se monitorea ----------

variable "cluster_name" {
  description = "Nombre del cluster de ECS."
  type        = string
}

variable "services" {
  description = "Servicios de ECS a monitorear y el grupo de logs de cada uno. Formato: { ui = \"/ecs/tero-dev/ui\", ... }."
  type        = map(string)
}

variable "alb_arn_suffix" {
  description = "Parte final del ARN del ALB público (por donde entran los usuarios)."
  type        = string
}

variable "target_groups" {
  description = "Target group de cada servicio y el ALB al que pertenece (público o interno). Formato: { ui = { load_balancer = \"app/...\", target_group = \"targetgroup/...\" } }."
  type = map(object({
    load_balancer = string
    target_group  = string
  }))
}

variable "admin_service" {
  description = "Servicio que atiende el login del panel de administración (para la alarma de seguridad)."
  type        = string
  default     = "admin"
}

variable "db_identifier" {
  description = "Nombre de la instancia RDS (por ejemplo, tero-dev-db)."
  type        = string
}

variable "redis_cluster_id" {
  description = "Nombre del cluster de ElastiCache Redis (por ejemplo, tero-dev-redis)."
  type        = string
}

# ---------- A dónde avisar ----------

variable "sns_topic_arn" {
  description = "Topic SNS de alertas (tero-alertas, creado en infra/shared). La Lambda de notificaciones lo manda por mail."
  type        = string
}

# ---------- Umbrales de las alarmas ----------

variable "error_rate_threshold" {
  description = "Porcentaje de respuestas 5xx (sobre el total de pedidos al ALB público) a partir del cual se alerta."
  type        = number
  default     = 5
}

variable "min_requests_for_error_rate" {
  description = "Cantidad mínima de pedidos en 5 minutos para calcular el porcentaje de errores (con muy pocos pedidos, 1 error ya sería un 50%)."
  type        = number
  default     = 10
}

variable "latency_p95_threshold_seconds" {
  description = "Tiempo de respuesta (percentil 95, en segundos) a partir del cual se alerta."
  type        = number
  default     = 2
}

variable "cpu_threshold" {
  description = "Porcentaje de CPU (del servicio que más use) a partir del cual se alerta."
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Porcentaje de memoria (del servicio que más use) a partir del cual se alerta."
  type        = number
  default     = 85
}

variable "admin_rejected_threshold" {
  description = "Cantidad de respuestas 4xx del panel de administración en 5 minutos a partir de la cual se alerta (posible fuerza bruta)."
  type        = number
  default     = 20
}
