# Módulo de notificaciones (issue #23).
#
#   Alarmas de CloudWatch ───────────┐
#                                    ├─> SNS "tero-alertas" ─> Lambda ─> SNS "tero-notificaciones-mail" ─> mails
#   Escaneo de ECR (HIGH/CRITICAL) ──┘
#        (EventBridge)
#
# - "tero-alertas" es el buzón de ENTRADA: cualquier alarma (issue #25) o
#   evento que quiera avisar al equipo publica ahí. Trae JSON de AWS.
# - La Lambda lo pasa en limpio (asunto + texto + link a la consola).
# - "tero-notificaciones-mail" es el buzón de SALIDA: manda el texto limpio
#   por mail a cada dirección suscrita (variable alert_emails).

data "aws_caller_identity" "current" {}

# El Learner Lab no deja crear roles de IAM: la Lambda usa LabRole, igual
# que ECS. LabRole ya puede escribir logs y publicar en SNS.
data "aws_iam_role" "lab" {
  name = "LabRole"
}

# =====================================================================
# 1) Topic SNS: el punto de entrada de todas las alertas
# =====================================================================

resource "aws_sns_topic" "alertas" {
  name = "${var.prefix}-alertas"

  # Sin cifrado KMS a propósito (igual que el de mail): con la clave
  # administrada de AWS (aws/sns) CloudWatch y EventBridge NO pueden
  # publicar, y una clave propia (CMK) cuesta USD 1/mes. Los mensajes no
  # llevan datos sensibles.

  tags = { Name = "${var.prefix}-alertas" }
}

# Quién puede publicar en el topic: los recursos de la cuenta (por ejemplo
# las alarmas de CloudWatch) y la regla de EventBridge de ECR.
# Sin la segunda parte, EventBridge no puede publicar.
resource "aws_sns_topic_policy" "alertas" {
  arn = aws_sns_topic.alertas.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CuentaPublica"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alertas.arn
        Condition = { StringEquals = { "AWS:SourceOwner" = data.aws_caller_identity.current.account_id } }
      },
      {
        Sid       = "EventBridgePublica"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alertas.arn
        # Solo la regla de ECR de este módulo, no cualquier regla
        Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.ecr_scan.arn } }
      },
    ]
  })
}

# =====================================================================
# 2) Topic SNS de salida: los mails
# =====================================================================

resource "aws_sns_topic" "mail" {
  name = "${var.prefix}-notificaciones-mail"

  tags = { Name = "${var.prefix}-notificaciones-mail" }
}

# Una suscripción por dirección. AWS manda un mail de confirmación a cada
# una y no envía nada hasta que la persona hace clic en "Confirm subscription".
resource "aws_sns_topic_subscription" "mail" {
  for_each = toset(var.alert_emails)

  topic_arn = aws_sns_topic.mail.arn
  protocol  = "email"
  endpoint  = each.value
}

# =====================================================================
# 3) La Lambda
# =====================================================================

# Empaqueta handler.py en un zip (Lambda recibe el código como zip)
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/build/notificaciones.zip"
}

# Grupo de logs creado por Terraform para fijar cuántos días se guardan
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.prefix}-notificaciones"
  retention_in_days = var.log_retention_days

  tags = { Name = "/aws/lambda/${var.prefix}-notificaciones" }
}

resource "aws_lambda_function" "notificaciones" {
  function_name = "${var.prefix}-notificaciones"
  description   = "Formatea alarmas y hallazgos de ECR y los manda por mail"
  role          = data.aws_iam_role.lab.arn

  runtime = "python3.12"
  handler = "handler.handler" # archivo handler.py, función handler

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256 # redeploy si cambia el código

  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      MAIL_TOPIC_ARN = aws_sns_topic.mail.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = { Name = "${var.prefix}-notificaciones" }
}

# =====================================================================
# 4) Conectar SNS de entrada -> Lambda
# =====================================================================

# La suscripción: cada mensaje del topic invoca la Lambda
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notificaciones.arn
}

# El permiso: la Lambda acepta ser invocada por ESTE topic (y nadie más)
resource "aws_lambda_permission" "sns" {
  statement_id  = "PermitirInvocacionDesdeSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notificaciones.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alertas.arn
}

# =====================================================================
# 5) EventBridge: escaneos de ECR con vulnerabilidades -> SNS
# =====================================================================
# ECR escanea cada imagen al subirla (scan_on_push). Cuando termina, AWS
# emite un evento "ECR Image Scan". Esta regla deja pasar solo los que
# tienen hallazgos CRITICAL o HIGH (los demás no avisan, para no hacer ruido).

resource "aws_cloudwatch_event_rule" "ecr_scan" {
  name        = "${var.prefix}-ecr-scan-hallazgos"
  description = "Escaneos de ECR con vulnerabilidades CRITICAL o HIGH"

  event_pattern = jsonencode({
    source        = ["aws.ecr"]
    "detail-type" = ["ECR Image Scan"]
    detail = {
      "scan-status" = ["COMPLETE"]
      # Al menos 1 hallazgo CRITICAL o al menos 1 HIGH (mismo criterio que Trivy en el CI)
      "$or" = [
        { "finding-severity-counts" = { CRITICAL = [{ numeric = [">", 0] }] } },
        { "finding-severity-counts" = { HIGH = [{ numeric = [">", 0] }] } },
      ]
    }
  })

  tags = { Name = "${var.prefix}-ecr-scan-hallazgos" }
}

resource "aws_cloudwatch_event_target" "ecr_scan_sns" {
  rule      = aws_cloudwatch_event_rule.ecr_scan.name
  target_id = "sns-alertas"
  arn       = aws_sns_topic.alertas.arn
}
