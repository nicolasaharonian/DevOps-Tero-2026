locals {
  # Prefijo de nombres: tero-dev, tero-test, tero-prod
  name = "tero-${var.environment}"
}

# Protección: evita aplicar el tfvars de un ambiente en el workspace de otro
# (por ejemplo, prod.tfvars estando en el workspace dev).

resource "terraform_data" "workspace_check" {
  lifecycle {
    precondition {
      condition     = var.environment == terraform.workspace
      error_message = "El tfvars es del ambiente '${var.environment}' pero el workspace activo es '${terraform.workspace}'. Ejecutar: terraform workspace select ${var.environment}"

    }
  }
}

module "network" {
  source   = "./modules/network"
  name     = local.name
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count
}

module "security" {
  source = "./modules/security"
  name   = local.name
  vpc_id = module.network.vpc_id
}

# Base de datos PostgreSQL (RDS) en las subredes privadas
module "database" {
  source            = "./modules/database"
  name              = local.name
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.db_sg_id

  instance_class        = var.db_instance_class
  multi_az              = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.db_deletion_protection
  skip_final_snapshot   = var.db_skip_final_snapshot
}

# Redis (ElastiCache) para el servicio checkout
module "cache" {
  source            = "./modules/cache"
  name              = local.name
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.redis_sg_id
  node_type         = var.redis_node_type
}

# Secretos de la aplicación (Secrets Manager)
module "secrets" {
  source      = "./modules/secrets"
  environment = var.environment
}

# Balanceador: recibe a los usuarios y reparte entre ui y admin
module "alb" {
  source            = "./modules/alb"
  name              = local.name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

# Balanceador interno: comunicación entre microservicios
# (reemplaza a Service Connect, que el Learner Lab no permite)
module "internal_alb" {
  source            = "./modules/internal-alb"
  name              = local.name
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.internal_alb_sg_id
}