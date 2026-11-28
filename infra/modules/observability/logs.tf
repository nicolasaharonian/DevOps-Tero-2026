# Consultas guardadas de CloudWatch Logs Insights.
# Los logs de los 6 servicios ya están centralizados en CloudWatch (un grupo
# /ecs/<ambiente>/<servicio> cada uno, ver modules/ecs-service). Estas
# consultas quedan guardadas en la consola (Logs Insights -> Queries, carpeta
# del ambiente) para buscar y filtrar en todos los servicios a la vez.

locals {
  log_group_names = [for s in local.service_names : var.services[s]]
}

# Errores en todos los servicios, el más nuevo primero
resource "aws_cloudwatch_query_definition" "errors" {
  name            = "${var.name}/errores-todos-los-servicios"
  log_group_names = local.log_group_names

  query_string = <<-QUERY
    fields @timestamp, @log, @message
    | filter @message like /(?i)(error|exception|fatal|panic)/
    | sort @timestamp desc
    | limit 100
  QUERY
}

# Cuántas líneas escribe cada servicio cada 5 minutos (un servicio que deja
# de escribir, o que de golpe escribe mucho más, suele ser una pista)
resource "aws_cloudwatch_query_definition" "volume" {
  name            = "${var.name}/actividad-por-servicio"
  log_group_names = local.log_group_names

  query_string = <<-QUERY
    stats count(*) as lineas by bin(5m), @log
  QUERY
}

# Respuestas HTTP por código y ruta de catalog y orders. Son de Go (Gin), que
# escribe una línea por pedido: "[GIN] fecha | 200 | 1.2ms | ip | GET "/ruta""
resource "aws_cloudwatch_query_definition" "http_status" {
  name = "${var.name}/respuestas-http-catalog-orders"
  log_group_names = [
    for s in ["catalog", "orders"] : var.services[s] if contains(keys(var.services), s)
  ]

  query_string = <<-QUERY
    filter @message like /^\[GIN\]/
    | parse @message /\|\s+(?<status>\d{3})\s+\|\s+(?<latencia>\S+)\s+\|\s+(?<ip>\S+)\s+\|\s+(?<metodo>[A-Z]+)\s+"(?<ruta>[^"]+)"/
    | stats count(*) as pedidos by @log, status, metodo, ruta
    | sort pedidos desc
  QUERY
}
