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