output "service_name" {

  description = "Nombre del servicio en ECS (para aws ecs update-service y para las métricas de CloudWatch)."
  value       = aws_ecs_service.this.name

}
 
output "task_definition_arn" {

  description = "ARN de la versión de la task definition que está desplegada."
  value       = aws_ecs_task_definition.this.arn

}
 
output "log_group_name" {

  description = "Grupo de logs de CloudWatch donde escribe el servicio."
  value       = aws_cloudwatch_log_group.this.name

}
 
output "internal_url" {

  description = "URL con la que lo llaman los otros servicios por Service Connect."
  value       = "http://${var.name}:${var.container_port}"

}
 