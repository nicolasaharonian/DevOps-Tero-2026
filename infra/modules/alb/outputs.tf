output "dns_name" {
  description = "Dirección pública del ALB (por ejemplo, tero-dev-alb-123.us-east-1.elb.amazonaws.com)."
  value       = aws_lb.this.dns_name
}
 
output "url" {
  description = "URL para entrar a la tienda desde el navegador."
  value       = "http://${aws_lb.this.dns_name}"
}
 
output "ui_target_group_arn" {
  description = "ARN del target group de ui (el servicio ECS de ui registra sus tareas acá)."
  value       = aws_lb_target_group.ui.arn
}
 
output "admin_target_group_arn" {
  description = "ARN del target group de admin (el servicio ECS de admin registra sus tareas acá)."
  value       = aws_lb_target_group.admin.arn
}
 
output "arn_suffix" {
  description = "Parte final del ARN del ALB. CloudWatch la usa para identificar el ALB en métricas y alarmas."
  value       = aws_lb.this.arn_suffix
}
 
output "ui_target_group_arn_suffix" {
  description = "Parte final del ARN del target group de ui, para métricas y alarmas de CloudWatch."
  value       = aws_lb_target_group.ui.arn_suffix
}
 
output "admin_target_group_arn_suffix" {
  description = "Parte final del ARN del target group de admin, para métricas y alarmas de CloudWatch."
  value       = aws_lb_target_group.admin.arn_suffix
}