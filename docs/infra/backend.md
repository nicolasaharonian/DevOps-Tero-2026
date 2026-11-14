# Backend remoto de Terraform

El estado de Terraform (state) se guarda en un bucket S3, para que todo el equipo

y el pipeline trabajen sobre la misma información. Es el único recurso que se crea

a mano, porque Terraform necesita que exista antes de poder guardar su estado.

## Bucket

- **Nombre:** `tero-tfstate-<número de cuenta>`

- **Región:** `us-east-1`

- **Creado:** a mano, desde la consola de AWS (S3 → Crear bucket).

| Configuración | Valor | Motivo |

|---|---|---|

| Bloqueo de acceso público | Bloquear todo el acceso público | Nadie fuera de la cuenta puede leer el state |

| Control de versiones | Habilitado | Permite recuperar versiones anteriores del state |

| Cifrado predeterminado | SSE-S3 (claves administradas por S3) | El state puede contener datos sensibles y se guarda cifrado |

| Clave de bucket | Habilitada | Optimización del cifrado recomendada por AWS |

Evidencia: `docs/evidencia/infra/`.

## Configuración en Terraform

Definida en `infra/versions.tf`:

- `encrypt = true`: el state se guarda cifrado.

- `use_lockfile = true`: bloquea el state mientras alguien ejecuta un `apply`, para

  que dos personas no lo modifiquen al mismo tiempo.

## Ambientes

Cada ambiente es un workspace de Terraform con su propio state dentro del bucket:

| Workspace | State |

|---|---|

| dev | `env:/dev/tero/terraform.tfstate` |

| test | `env:/test/tero/terraform.tfstate` |

| prod | `env:/prod/tero/terraform.tfstate` |

## Uso

    cd infra

    terraform init                      # solo la primera vez

    terraform workspace select dev      # elegir el ambiente

    terraform plan                      # ver qué va a cambiar

    terraform apply                     # aplicar los cambios

> **Learner Lab:** las credenciales de AWS vencen al terminar la sesión del lab.
> Antes de usar Terraform, copiar las credenciales actualizadas en `~/.aws/credentials`.
