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

# ---------- catalog: productos (interno) ----------
 
module "catalog" {
  source = "./modules/ecs-service"
 
  # Qué correr
  name  = "catalog"
  image = "${local.ecr_registry}/tero/catalog:${local.image_tag}"
 
  # Sus variables: las mismas que catalog tiene en el docker-compose.yml
  environment = {
    GIN_MODE                            = "release"
    RETAIL_CATALOG_PERSISTENCE_PROVIDER = "postgres"
    RETAIL_CATALOG_PERSISTENCE_ENDPOINT = module.database.endpoint
    RETAIL_CATALOG_PERSISTENCE_DB_NAME  = "catalogdb"
    RETAIL_CATALOG_PERSISTENCE_USER     = module.database.username
  }
 
  # La contraseña de la base se lee de Secrets Manager al arrancar
  secrets = {
    RETAIL_CATALOG_PERSISTENCE_PASSWORD = "${module.database.master_secret_arn}:password::"
  }
 
  # Es interno: se anota en el ALB interno
  target_group_arn = module.internal_alb.target_group_arns["catalog"]
 
  # Dónde y con qué permisos (igual en todos los servicios)
  prefix             = local.name
  cluster_id         = aws_ecs_cluster.this.id
  subnet_ids         = module.network.public_subnet_ids
  security_group_id  = module.security.ecs_sg_id
  execution_role_arn = data.aws_iam_role.lab.arn
  task_role_arn      = data.aws_iam_role.lab.arn
}

# ---------- carts: carrito (interno) ----------
 
module "carts" {
  source = "./modules/ecs-service"
 
  # Qué correr (el repositorio se llama carts, aunque la carpeta del código es src/cart)
  name  = "carts"
  image = "${local.ecr_registry}/tero/carts:${local.image_tag}"
 
  # Sus variables: las mismas que carts tiene en el docker-compose.yml
  environment = {
    CART_PERSISTENCE_PROVIDER = "postgres"
    CART_POSTGRES_HOST        = module.database.address
    CART_POSTGRES_PORT        = tostring(module.database.port)
    CART_POSTGRES_DB          = "cartdb"
    CART_POSTGRES_USER        = module.database.username
    PORT                      = "8080"
  }
 
  # La contraseña de la base se lee de Secrets Manager al arrancar
  secrets = {
    CART_POSTGRES_PASSWORD = "${module.database.master_secret_arn}:password::"
  }
 
  # Es interno: se anota en el ALB interno
  target_group_arn = module.internal_alb.target_group_arns["carts"]
 
  # Dónde y con qué permisos (igual en todos los servicios)
  prefix             = local.name
  cluster_id         = aws_ecs_cluster.this.id
  subnet_ids         = module.network.public_subnet_ids
  security_group_id  = module.security.ecs_sg_id
  execution_role_arn = data.aws_iam_role.lab.arn
  task_role_arn      = data.aws_iam_role.lab.arn
}

# ---------- orders: órdenes de compra (interno) ----------
 
module "orders" {
  source = "./modules/ecs-service"
 
  # Qué correr
  name  = "orders"
  image = "${local.ecr_registry}/tero/orders:${local.image_tag}"
 
  # Sus variables: las mismas que orders tiene en el docker-compose.yml
  environment = {
    GIN_MODE                           = "release"
    RETAIL_ORDERS_PERSISTENCE_ENDPOINT = module.database.endpoint
    RETAIL_ORDERS_PERSISTENCE_NAME     = "orders"
    RETAIL_ORDERS_PERSISTENCE_USERNAME = module.database.username
  }
 
  # La contraseña de la base se lee de Secrets Manager al arrancar
  secrets = {
    RETAIL_ORDERS_PERSISTENCE_PASSWORD = "${module.database.master_secret_arn}:password::"
  }
 
  # Es interno: se anota en el ALB interno
  target_group_arn = module.internal_alb.target_group_arns["orders"]
 
  # Dónde y con qué permisos (igual en todos los servicios)
  prefix             = local.name
  cluster_id         = aws_ecs_cluster.this.id
  subnet_ids         = module.network.public_subnet_ids
  security_group_id  = module.security.ecs_sg_id
  execution_role_arn = data.aws_iam_role.lab.arn
  task_role_arn      = data.aws_iam_role.lab.arn
}