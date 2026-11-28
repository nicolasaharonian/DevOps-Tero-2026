# Dashboard de CloudWatch del ambiente: una sola pantalla para ver si Tero
# anda bien. Se lee de arriba hacia abajo:
#   1) ¿Hay alarmas sonando?
#   2) ¿Qué ven los usuarios? (pedidos, errores, latencia en el ALB público)
#   3) ¿Están vivos los servicios? (tareas sanas y corriendo)
#   4) ¿Les alcanzan los recursos? (CPU y memoria de cada servicio)
#   5) ¿Cómo están la base y Redis?
#   6) ¿Qué errores aparecen en los logs?
#
# El tablero tiene 24 columnas de ancho; cada widget dice dónde va (x, y)
# y cuánto ocupa (width, height).

locals {
  service_names = sort(keys(var.services))

  # Una línea por servicio, para los gráficos de ECS
  ecs_metric_lines = {
    for metric in ["CPUUtilization", "MemoryUtilization"] : metric => [
      for s in local.service_names : ["AWS/ECS", metric, "ClusterName", var.cluster_name, "ServiceName", s, { label = s }]
    ]
  }

  # Errores en los logs de todos los servicios (Logs Insights)
  log_sources      = join(" | ", [for s in local.service_names : "SOURCE '${var.services[s]}'"])
  log_error_filter = "filter @message like /(?i)(error|exception|fatal|panic)/"

  widgets = [
    # ---------- Fila 1: título y alarmas ----------
    {
      type = "text", x = 0, y = 0, width = 8, height = 6
      properties = {
        markdown = join("\n", [
          "# Tero - ${var.name}",
          "Estado del ambiente. Si llega un mail de alarma, empezar por acá.",
          "",
          "* Arriba a la derecha: alarmas (rojo = sonando).",
          "* Qué hacer ante cada alarma: `docs/infra/observabilidad.md`.",
          "* Logs de un servicio: grupo `/ecs/${var.name}/<servicio>`.",
          "* Consultas guardadas: Logs Insights, carpeta `${var.name}`.",
        ])
      }
    },
    {
      type = "alarm", x = 8, y = 0, width = 16, height = 6
      properties = {
        title  = "Alarmas"
        alarms = local.all_alarm_arns
      }
    },

    # ---------- Fila 2: lo que ven los usuarios (ALB público) ----------
    {
      type = "metric", x = 0, y = 6, width = 8, height = 6
      properties = {
        title   = "Pedidos a la tienda (por minuto)"
        region  = var.region
        view    = "timeSeries"
        stat    = "Sum"
        period  = 60
        metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Pedidos" }]]
      }
    },
    {
      type = "metric", x = 8, y = 6, width = 8, height = 6
      properties = {
        title  = "Errores (por minuto)"
        region = var.region
        view   = "timeSeries"
        stat   = "Sum"
        period = 60
        metrics = [
          ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "5xx de los servicios", color = "#d62728" }],
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "5xx del ALB", color = "#ff7f0e" }],
          ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "4xx (pedido inválido o no autorizado)", color = "#bcbd22" }],
        ]
      }
    },
    {
      type = "metric", x = 16, y = 6, width = 8, height = 6
      properties = {
        title  = "Tiempo de respuesta (segundos)"
        region = var.region
        view   = "timeSeries"
        period = 60
        metrics = [
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50", label = "p50 (pedido típico)" }],
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p95", label = "p95 (los más lentos)" }],
        ]
        annotations = {
          horizontal = [{ label = "Umbral de la alarma", value = var.latency_p95_threshold_seconds }]
        }
      }
    },

    # ---------- Fila 3: ¿están vivos los servicios? ----------
    {
      type = "metric", x = 0, y = 12, width = 12, height = 6
      properties = {
        title  = "Tareas sanas por servicio (según el ALB)"
        region = var.region
        view   = "timeSeries"
        stat   = "Minimum"
        period = 60
        metrics = [
          for s, tg in var.target_groups :
          ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", tg.load_balancer, "TargetGroup", tg.target_group, { label = s }]
        ]
        annotations = {
          horizontal = [{ label = "Menos de 1 = caído", value = 1 }]
        }
      }
    },
    {
      type = "metric", x = 12, y = 12, width = 12, height = 6
      properties = {
        title  = "Tareas corriendo por servicio (Container Insights)"
        region = var.region
        view   = "timeSeries"
        stat   = "Average"
        period = 60
        metrics = [
          for s in local.service_names :
          ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.cluster_name, "ServiceName", s, { label = s }]
        ]
      }
    },

    # ---------- Fila 4: recursos de cada servicio ----------
    {
      type = "metric", x = 0, y = 18, width = 12, height = 6
      properties = {
        title   = "CPU por servicio (%)"
        region  = var.region
        view    = "timeSeries"
        stat    = "Average"
        period  = 60
        metrics = local.ecs_metric_lines["CPUUtilization"]
        yAxis   = { left = { min = 0, max = 100 } }
        annotations = {
          horizontal = [{ label = "Umbral de la alarma", value = var.cpu_threshold }]
        }
      }
    },
    {
      type = "metric", x = 12, y = 18, width = 12, height = 6
      properties = {
        title   = "Memoria por servicio (%)"
        region  = var.region
        view    = "timeSeries"
        stat    = "Average"
        period  = 60
        metrics = local.ecs_metric_lines["MemoryUtilization"]
        yAxis   = { left = { min = 0, max = 100 } }
        annotations = {
          horizontal = [{ label = "Umbral de la alarma", value = var.memory_threshold }]
        }
      }
    },

    # ---------- Fila 5: base de datos y Redis ----------
    {
      type = "metric", x = 0, y = 24, width = 8, height = 6
      properties = {
        title  = "Base de datos (RDS)"
        region = var.region
        view   = "timeSeries"
        period = 60
        metrics = [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_identifier, { stat = "Average", label = "CPU (%)" }],
          ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier, { stat = "Maximum", label = "Conexiones abiertas", yAxis = "right" }],
        ]
      }
    },
    {
      type = "metric", x = 8, y = 24, width = 8, height = 6
      properties = {
        title  = "Espacio libre en la base (GB)"
        region = var.region
        view   = "timeSeries"
        period = 300
        metrics = [
          [{ expression = "libre / 1000000000", label = "GB libres", id = "gb" }],
          ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_identifier, { stat = "Minimum", id = "libre", visible = false }],
        ]
      }
    },
    {
      type = "metric", x = 16, y = 24, width = 8, height = 6
      properties = {
        title  = "Redis (ElastiCache)"
        region = var.region
        view   = "timeSeries"
        period = 60
        metrics = [
          ["AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", var.redis_cluster_id, "CacheNodeId", "0001", { stat = "Average", label = "CPU de Redis (%)" }],
          ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", var.redis_cluster_id, "CacheNodeId", "0001", { stat = "Average", label = "Memoria usada (%)" }],
          ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", var.redis_cluster_id, "CacheNodeId", "0001", { stat = "Maximum", label = "Conexiones", yAxis = "right" }],
        ]
      }
    },

    # ---------- Fila 6: logs ----------
    {
      type = "log", x = 0, y = 30, width = 10, height = 6
      properties = {
        title  = "Líneas de error por servicio (en el período elegido)"
        region = var.region
        view   = "bar"
        query  = "${local.log_sources} | ${local.log_error_filter} | stats count(*) as errores by @log"
      }
    },
    {
      type = "log", x = 10, y = 30, width = 14, height = 6
      properties = {
        title  = "Últimos errores en los logs (todos los servicios)"
        region = var.region
        view   = "table"
        query  = "${local.log_sources} | fields @timestamp, @log, @message | ${local.log_error_filter} | sort @timestamp desc | limit 50"
      }
    },
  ]
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name
  dashboard_body = jsonencode({ widgets = local.widgets })
}
