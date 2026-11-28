output "sns_topic_arn" {
  description = "ARN del topic SNS de alertas. Las alarmas de CloudWatch lo usan en alarm_actions/ok_actions."
  value       = aws_sns_topic.alertas.arn
}

output "sns_topic_name" {
  description = "Nombre del topic SNS de alertas (para buscarlo con data \"aws_sns_topic\" desde infra/)."
  value       = aws_sns_topic.alertas.name
}

output "lambda_name" {
  description = "Nombre de la Lambda de notificaciones."
  value       = aws_lambda_function.notificaciones.function_name
}

output "mail_topic_arn" {
  description = "ARN del topic SNS que manda los mails (salida de la Lambda)."
  value       = aws_sns_topic.mail.arn
}
