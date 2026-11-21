output "url" {
  description = "URL del ALB interno. Es la que usan ui y checkout para llamar a los otros servicios."
  value       = "http://${aws_lb.this.dns_name}"
}

output "target_group_arns" {
  description = "ARN del target group de cada servicio interno ({ catalog = arn, carts = arn, ... })."
  value       = { for name, tg in aws_lb_target_group.this : name => tg.arn }
}

output "arn_suffix" {
  description = "Parte final del ARN del ALB interno, para métricas y alarmas de CloudWatch."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffixes" {
  description = "Parte final del ARN de cada target group, para métricas y alarmas de CloudWatch."
  value       = { for name, tg in aws_lb_target_group.this : name => tg.arn_suffix }
}