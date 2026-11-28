# Módulo observability: dashboard, alarmas y consultas de logs de un ambiente.
#
#   alarms.tf    -> 5 tipos de alarma (disponibilidad, errores, latencia,
#                   CPU/memoria, seguridad del admin), avisan a tero-alertas
#   dashboard.tf -> el dashboard de CloudWatch "tero-<ambiente>"
#   logs.tf      -> consultas guardadas de Logs Insights
#
# Las métricas ya las publica AWS solo (ALB, ECS con Container Insights,
# RDS, ElastiCache) y los logs ya llegan a CloudWatch por el driver awslogs:
# este módulo no instala agentes ni cambia los servicios.
