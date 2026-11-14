variable "prefix" {
  description = "Prefijo de los repositorios (por ejemplo, tero → tero/catalog)."
  type        = string
}
 
variable "repositories" {
  description = "Nombres de los repositorios a crear, uno por microservicio."
  type        = list(string)
}
 
variable "max_images" {
  description = "Cantidad de imágenes a conservar por repositorio. Las más viejas se borran automáticamente."
  type        = number
  default     = 10
}