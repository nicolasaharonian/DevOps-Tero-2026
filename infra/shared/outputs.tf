output "ecr_repository_urls" {
  description = "Dirección de cada repositorio de ECR, por nombre de servicio."
  value       = module.ecr.repository_urls
}

output "ecr_registry_url" {
  description = "Dirección del registro de ECR de la cuenta (para docker login)."
  value       = module.ecr.registry_url
}
output "alertas_sns_topic_arn" {
  description = "ARN del topic SNS de alertas: usarlo en alarm_actions/ok_actions de las alarmas (issue #25)."
  value       = module.notifications.sns_topic_arn
}

output "notificaciones_lambda" {
  description = "Nombre de la Lambda que formatea las alertas y las manda por mail."
  value       = module.notifications.lambda_name
}

output "notificaciones_mail_topic_arn" {
  description = "ARN del topic SNS que manda los mails (para ver las suscripciones y su confirmación)."
  value       = module.notifications.mail_topic_arn
}
