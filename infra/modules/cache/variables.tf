variable "name" {
  description = "Prefijo para los nombres de los recursos (por ejemplo, tero-dev)."
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas donde vive Redis."
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group de Redis (redis-sg del módulo security)."
  type        = string
}

variable "engine_version" {
  description = "Versión de Redis (la misma mayor que redis:7 del docker-compose)."
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "Tamaño del nodo de ElastiCache."
  type        = string
  default     = "cache.t3.micro"
}
