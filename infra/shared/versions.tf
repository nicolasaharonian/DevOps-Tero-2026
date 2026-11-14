# Raíz COMPARTIDA: recursos que existen una sola vez para todos los ambientes (ECR).
# No usa workspaces: siempre se trabaja en el workspace "default".

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "tero-tfstate-564285963750"
    key          = "tero/shared.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "tero"
      Environment = "shared"
      ManagedBy   = "terraform"
    }
  }
}
