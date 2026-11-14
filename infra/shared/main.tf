# Repositorios de imágenes Docker, compartidos por los ambientes dev, test y prod.
# La misma imagen (mismo tag) se promueve de un ambiente a otro.

module "ecr" {
  source       = "../modules/ecr"
  prefix       = "tero"
  repositories = ["ui", "catalog", "carts", "orders", "checkout", "admin"]
  max_images   = 10
}
 