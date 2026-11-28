# Repositorios de imágenes Docker, compartidos por los ambientes dev, test y prod.
# La misma imagen (mismo tag) se promueve de un ambiente a otro.

module "ecr" {
  source       = "../modules/ecr"
  prefix       = "tero"
  repositories = ["ui", "catalog", "carts", "orders", "checkout", "admin"]
  max_images   = 10
}

# Notificaciones (issue #23): topic SNS de alertas + Lambda que avisa por
# mail. Es compartido porque ECR es uno solo y porque así las alarmas de dev,
# test y prod llegan al mismo lugar (y sigue funcionando aunque se destruya
# un ambiente).
module "notifications" {
  source       = "../modules/notifications"
  prefix       = "tero"
  alert_emails = var.alert_emails
}
