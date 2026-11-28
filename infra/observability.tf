# Observabilidad del ambiente (issues #24 y #25): dashboard, alarmas y
# consultas de logs. Ver docs/infra/observabilidad.md.

# Topic de alertas creado en infra/shared (issue #23). Se busca por nombre
# para no depender del state de shared. Lo que llega acá sale por mail.
data "aws_sns_topic" "alertas" {
  name = "tero-alertas"
}

locals {
  # Los 6 servicios de ECS y su grupo de logs
  ecs_services = {
    ui       = module.ui
    catalog  = module.catalog
    carts    = module.carts
    orders   = module.orders
    checkout = module.checkout
    admin    = module.admin
  }
}

module "observability" {
  source = "./modules/observability"

  name   = local.name
  region = data.aws_region.current.region

  cluster_name = aws_ecs_cluster.this.name
  services     = { for s, m in local.ecs_services : m.service_name => m.log_group_name }

  # ALB público: por donde entran los usuarios
  alb_arn_suffix = module.alb.arn_suffix

  # Target group de cada servicio: ui y admin en el ALB público,
  # el resto en el ALB interno
  target_groups = merge(
    {
      ui    = { load_balancer = module.alb.arn_suffix, target_group = module.alb.ui_target_group_arn_suffix }
      admin = { load_balancer = module.alb.arn_suffix, target_group = module.alb.admin_target_group_arn_suffix }
    },
    {
      for s, tg in module.internal_alb.target_group_arn_suffixes :
      s => { load_balancer = module.internal_alb.arn_suffix, target_group = tg }
    }
  )

  db_identifier    = module.database.identifier
  redis_cluster_id = module.cache.cluster_id

  sns_topic_arn = data.aws_sns_topic.alertas.arn
}
