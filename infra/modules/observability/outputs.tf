locals {
  all_alarm_arns = concat(
    [for a in aws_cloudwatch_metric_alarm.service_down : a.arn],
    [
      aws_cloudwatch_metric_alarm.error_rate.arn,
      aws_cloudwatch_metric_alarm.latency.arn,
      aws_cloudwatch_metric_alarm.cpu.arn,
      aws_cloudwatch_metric_alarm.memory.arn,
      aws_cloudwatch_metric_alarm.admin_rejected.arn,
    ]
  )
}

output "dashboard_name" {
  description = "Nombre del dashboard de CloudWatch."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "dashboard_url" {
  description = "Link directo al dashboard en la consola de AWS."
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards/dashboard/${aws_cloudwatch_dashboard.this.dashboard_name}"
}

output "alarm_names" {
  description = "Nombres de todas las alarmas del ambiente."
  value = concat(
    [for a in aws_cloudwatch_metric_alarm.service_down : a.alarm_name],
    [
      aws_cloudwatch_metric_alarm.error_rate.alarm_name,
      aws_cloudwatch_metric_alarm.latency.alarm_name,
      aws_cloudwatch_metric_alarm.cpu.alarm_name,
      aws_cloudwatch_metric_alarm.memory.alarm_name,
      aws_cloudwatch_metric_alarm.admin_rejected.alarm_name,
    ]
  )
}
