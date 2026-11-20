variable "name" {

  description = "Prefijo para los nombres de los recursos (por ejemplo, tero-dev)."
  type        = string

}

variable "vpc_id" {

  description = "ID de la VPC donde se crean los security groups."
  type        = string

}

variable "alb_port" {

  description = "Puerto en el que el ALB recibe tráfico desde internet (HTTP)."
  type        = number
  default     = 80

}

variable "app_port" {

  description = "Puerto en el que escuchan los microservicios dentro de los contenedores."
  type        = number
  default     = 8080

}

variable "db_port" {

  description = "Puerto de PostgreSQL (RDS)."
  type        = number
  default     = 5432

}

variable "redis_port" {

  description = "Puerto de Redis (ElastiCache)."
  type        = number
  default     = 6379

}
 