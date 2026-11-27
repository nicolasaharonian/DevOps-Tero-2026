terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    # Para armar el zip con el código de la Lambda
    archive = {
      source = "hashicorp/archive"
    }
  }
}
