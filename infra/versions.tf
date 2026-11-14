# Versiones de Terraform y del proveedor de AWS, y dónde se guarda el state.
 
terraform {

  required_version = ">= 1.10"
 
  required_providers {

    aws = {

      source  = "hashicorp/aws"

      version = "~> 6.0"

    }

  }
 
  # Backend remoto: el state se guarda en el bucket S3 creado a mano
  # (ver docs/infra/backend.md). Cada workspace (dev, test, prod) tiene
  # su propio state dentro del bucket.

  backend "s3" {

    bucket       = "tero-tfstate-564285963750"

    key          = "tero/terraform.tfstate"

    region       = "us-east-1"

    encrypt      = true

    use_lockfile = true

  }

}
 
provider "aws" {

  region = "us-east-1"
 
  # Etiquetas que se agregan a TODOS los recursos que cree Terraform.

  default_tags {

    tags = {

      Project     = "tero"

      Environment = terraform.workspace

      ManagedBy   = "terraform"

    }

  }

}
 