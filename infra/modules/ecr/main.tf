# Módulo ECR: un repositorio de imágenes Docker por microservicio.

resource "aws_ecr_repository" "this" {

  for_each = toset(var.repositories)
  name     = "${var.prefix}/${each.key}"

  # Tags inmutables: una vez publicada una versión (por ejemplo catalog:a1b2c3d),
  # no se puede sobrescribir con otra imagen.

  image_tag_mutability = "IMMUTABLE"

  # AWS escanea cada imagen apenas se sube (segunda capa además de Trivy en el CI).

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # Permite borrar el repositorio con terraform destroy aunque tenga imágenes.
  # Útil en Learner Lab; en una cuenta productiva convendría dejarlo en false.

  force_delete = true

}

# Política de limpieza: conserva solo las últimas N imágenes de cada repositorio.

resource "aws_ecr_lifecycle_policy" "this" {

  for_each   = aws_ecr_repository.this
  repository = each.value.name
  policy = jsonencode({

    rules = [

      {
        rulePriority = 1
        description  = "Conservar solo las ultimas ${var.max_images} imagenes"
        selection = {

          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_images

        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}
 