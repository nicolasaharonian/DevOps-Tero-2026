# Alarmas de CloudWatch. Todas avisan al topic tero-alertas (infra/shared):
# SNS -> Lambda de notificaciones -> mail. Avisan al entrar en ALARM y
# también cuando vuelven a OK.
#
# Qué cubre cada una (la letra pide disponibilidad, rendimiento, seguridad
# y/o recursos) y qué hacer cuando llega el mail: docs/infra/observabilidad.md

locals {
  alarm_actions = [var.sns_topic_arn]
}

# =====================================================================
# 1) DISPONIBILIDAD: un servicio se quedó sin tareas sanas
# =====================================================================
# El ALB revisa la salud de cada tarea (health check). Si un servicio
# no tiene ninguna tarea sana durante 3 minutos seguidos, está caído.
# Una por servicio, así el mail dice cuál es.

resource "aws_cloudwatch_metric_alarm" "service_down" {
  for_each = var.target_groups

  alarm_name        = "${var.name}-${each.key}-sin-tareas-sanas"
  alarm_description = "DISPONIBILIDAD: ${each.key} no tiene ninguna tarea sana detrás del balanceador. Runbook: docs/infra/observabilidad.md#servicio-caído"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"
  dimensions = {
    LoadBalancer = each.value.load_balancer
    TargetGroup  = each.value.target_group
  }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = 1

  # Si la métrica deja de llegar, se toma como caído (no como "todo bien")
  treat_missing_data = "breaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# =====================================================================
# 2) RENDIMIENTO: demasiados errores 5xx para los usuarios
# =====================================================================
# Porcentaje de pedidos que terminan en error del servidor (5xx), sea del
# servicio (Target) o del propio ALB (por ejemplo, 503 porque no hay a
# quién mandarle). Se calcula con "metric math" sobre 3 métricas.

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name        = "${var.name}-errores-5xx"
  alarm_description = "RENDIMIENTO: más del ${var.error_rate_threshold}% de los pedidos a la tienda terminan en error 5xx. Runbook: docs/infra/observabilidad.md#errores-5xx"

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.error_rate_threshold
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching" # sin pedidos no hay errores

  metric_query {
    id          = "porcentaje"
    label       = "% de pedidos con 5xx"
    return_data = true
    # Solo se calcula si hubo un mínimo de pedidos (evita falsas alarmas)
    expression = "IF(pedidos >= ${var.min_requests_for_error_rate}, 100 * (FILL(error_alb, 0) + FILL(error_servicio, 0)) / pedidos, 0)"
  }

  metric_query {
    id = "pedidos"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
      stat        = "Sum"
      period      = 300
    }
  }

  metric_query {
    id = "error_alb"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
      stat        = "Sum"
      period      = 300
    }
  }

  metric_query {
    id = "error_servicio"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
      stat        = "Sum"
      period      = 300
    }
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# =====================================================================
# 3) RENDIMIENTO: la tienda responde lento
# =====================================================================
# p95 = el 95% de los pedidos tarda menos que este valor. Se usa p95 y
# no el promedio porque el promedio esconde a los usuarios que esperan mucho.

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name        = "${var.name}-latencia-alta"
  alarm_description = "RENDIMIENTO: el 5% más lento de los pedidos a la tienda tarda más de ${var.latency_p95_threshold_seconds} s (p95). Runbook: docs/infra/observabilidad.md#latencia-alta"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  extended_statistic  = "p95"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.latency_p95_threshold_seconds
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# =====================================================================
# 4) RECURSOS: CPU y memoria de los servicios
# =====================================================================
# Una sola alarma para los 6 servicios: toma el MÁXIMO entre todos.
# El mail dice "algún servicio está al límite" y el dashboard dice cuál.

locals {
  # Los ids de metric math tienen que empezar en minúscula y no llevar guiones
  service_ids = { for s in keys(var.services) : s => replace(s, "-", "_") }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name        = "${var.name}-cpu-alta"
  alarm_description = "RECURSOS: algún servicio usa más del ${var.cpu_threshold}% de su CPU. Runbook: docs/infra/observabilidad.md#cpu-o-memoria-alta"

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_threshold
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "maximo"
    label       = "CPU del servicio que más usa (%)"
    return_data = true
    expression  = "MAX([${join(", ", [for s, id in local.service_ids : "cpu_${id}"])}])"
  }

  dynamic "metric_query" {
    for_each = local.service_ids
    content {
      id = "cpu_${metric_query.value}"
      metric {
        namespace   = "AWS/ECS"
        metric_name = "CPUUtilization"
        dimensions = {
          ClusterName = var.cluster_name
          ServiceName = metric_query.key
        }
        stat   = "Average"
        period = 300
      }
    }
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name        = "${var.name}-memoria-alta"
  alarm_description = "RECURSOS: algún servicio usa más del ${var.memory_threshold}% de su memoria. Runbook: docs/infra/observabilidad.md#cpu-o-memoria-alta"

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.memory_threshold
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "maximo"
    label       = "Memoria del servicio que más usa (%)"
    return_data = true
    expression  = "MAX([${join(", ", [for s, id in local.service_ids : "mem_${id}"])}])"
  }

  dynamic "metric_query" {
    for_each = local.service_ids
    content {
      id = "mem_${metric_query.value}"
      metric {
        namespace   = "AWS/ECS"
        metric_name = "MemoryUtilization"
        dimensions = {
          ClusterName = var.cluster_name
          ServiceName = metric_query.key
        }
        stat   = "Average"
        period = 300
      }
    }
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# =====================================================================
# 5) SEGURIDAD: muchos accesos rechazados al panel de administración
# =====================================================================
# El admin responde 401 cuando el usuario o la contraseña están mal.
# Muchos 4xx en poco tiempo pueden ser alguien probando contraseñas
# (fuerza bruta). Es una señal para mirar, no una prueba.

resource "aws_cloudwatch_metric_alarm" "admin_rejected" {
  alarm_name        = "${var.name}-admin-accesos-rechazados"
  alarm_description = "SEGURIDAD: más de ${var.admin_rejected_threshold} respuestas 4xx del panel de administración en 5 minutos (posible fuerza bruta). Runbook: docs/infra/observabilidad.md#accesos-rechazados-al-admin"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_4XX_Count"
  dimensions = {
    LoadBalancer = var.target_groups[var.admin_service].load_balancer
    TargetGroup  = var.target_groups[var.admin_service].target_group
  }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.admin_rejected_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}
