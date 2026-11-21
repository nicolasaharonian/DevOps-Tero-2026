# Los microservicios de Tero en ECS. Cada uno usa el molde modules/ecs-service.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Última imagen de ui publicada en ECR (el CD publica los 6 servicios con el mismo tag)
data "aws_ecr_image" "latest" {
  repository_name = "tero/ui"
  most_recent     = true
}

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"

  # Si se pasó image_tag, se usa ese; si no, el de la última imagen
  image_tag = coalesce(var.image_tag, data.aws_ecr_image.latest.image_tags[0])
}

# ---------- ui: la tienda ----------

module "ui" {
  source = "./modules/ecs-service"

  # Qué correr
  name  = "ui"
  image = "${local.ecr_registry}/tero/ui:${local.image_tag}"

  # Sus variables: las mismas que ui tiene en el docker-compose.yml,
  # pero en lugar de http://catalog:8080 apuntan al ALB interno
  environment = {
    RETAIL_UI_ENDPOINTS_CATALOG  = module.internal_alb.url
    RETAIL_UI_ENDPOINTS_CARTS    = module.internal_alb.url
    RETAIL_UI_ENDPOINTS_CHECKOUT = module.internal_alb.url
    RETAIL_UI_ENDPOINTS_ORDERS   = module.internal_alb.url
  }

  # Es pública: se anota en el ALB público
  target_group_arn = module.alb.ui_target_group_arn

  # Dónde y con qué permisos (igual en todos los servicios)
  prefix             = local.name
  cluster_id         = aws_ecs_cluster.this.id
  subnet_ids         = module.network.public_subnet_ids
  security_group_id  = module.security.ecs_sg_id
  execution_role_arn = data.aws_iam_role.lab.arn
  task_role_arn      = data.aws_iam_role.lab.arn
}