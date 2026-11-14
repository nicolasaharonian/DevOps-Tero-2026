# Registro de imágenes (ECR)

Las imágenes Docker de los microservicios se publican en **Amazon ECR**, el registro privado
de contenedores de AWS. El pipeline de CI/CD sube cada imagen una sola vez y los ambientes
dev, test y prod la descargan desde ahí.

## Repositorios

Un repositorio por microservicio:

| Servicio | Repositorio     |
| -------- | --------------- |
| ui       | `tero/ui`       |
| catalog  | `tero/catalog`  |
| carts    | `tero/carts`    |
| orders   | `tero/orders`   |
| checkout | `tero/checkout` |
| admin    | `tero/admin`    |

Registro: `<cuenta>.dkr.ecr.us-east-1.amazonaws.com`

## Configuración

| Configuración        | Valor                            | Motivo                                                                                                                                                    |
| -------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tags inmutables      | `IMMUTABLE`                      | Una versión publicada (por ejemplo `catalog:a1b2c3d`) no puede sobrescribirse. Garantiza que dev, test y prod ejecuten exactamente la misma imagen        |
| Escaneo al publicar  | Activado                         | AWS escanea cada imagen al subirla, como capa adicional al escaneo de Trivy en el CI                                                                      |
| Cifrado              | AES256                           | Las imágenes se almacenan cifradas                                                                                                                        |
| Política de limpieza | Conserva las últimas 10 imágenes | Evita acumular imágenes (el almacenamiento tiene costo) y permite volver a versiones anteriores                                                           |
| `force_delete`       | `true`                           | Permite eliminar los repositorios con `terraform destroy` aunque tengan imágenes. Adecuado para Learner Lab; en una cuenta productiva debería ser `false` |

## Decisión de diseño: ECR compartido entre ambientes

A diferencia de la red, que existe una vez por ambiente, ECR es **único y compartido**.
El principio es _build once, promote many_: la imagen se construye una sola vez y la misma
(mismo tag) se promueve de dev a test y de test a prod. Si cada ambiente tuviera su propio
registro, habría que reconstruir o copiar la imagen en cada paso y no habría garantía de
que fuera la misma que se probó.

Por eso ECR se define en una **raíz de Terraform separada**, `infra/shared/`, que no usa
workspaces y guarda su estado en `tero/shared.tfstate` (mismo bucket que el resto).

| Raíz            | Workspaces          | State                                    | Contenido                                           |
| --------------- | ------------------- | ---------------------------------------- | --------------------------------------------------- |
| `infra/`        | dev, test, prod     | `env:/<ambiente>/tero/terraform.tfstate` | Recursos por ambiente (red, y luego ECS, RDS, etc.) |
| `infra/shared/` | ninguno (`default`) | `tero/shared.tfstate`                    | Recursos compartidos (ECR)                          |

## Uso

```bash
cd infra/shared
terraform init
terraform plan
terraform apply
terraform output     # direcciones de los repositorios
```
