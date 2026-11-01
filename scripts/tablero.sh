#!/usr/bin/env bash
# Automatiza etiquetas, issues y carga al GitHub Project Tero.
# Seguro para ejecutar varias veces: no duplica issues ni reinicia
# estados de tareas que ya existen en el tablero.
 
set -euo pipefail
 
# ===== CONFIGURACION =====
OWNER="nicolasaharonian"
REPO="$OWNER/DevOps-Tero-2026"
 
PROJECT_NUMBER="3"
PROJECT_ID="PVT_kwHOCq-g6s4BptEv"
PROJECT="DevOps-Tablero-Kanban"
 
STATUS_FIELD_ID="PVTSSF_lAHOCq-g6s4BptEvzhoHcac"
 
BACKLOG_ID="9eafd2a0"
TODO_ID="f75ad846"
IN_PROGRESS_ID="47fc9ee4"
IN_REVIEW_ID="fc52be69"
DONE_ID="98236657"
 
EXISTING_SECRET_ISSUE="https://github.com/$REPO/issues/1"
# ==========================
 
# Verificar dependencias
for cmd in gh jq; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: falta instalar $cmd"
    exit 1
  }
done
 
gh auth status >/dev/null 2>&1 || {
  echo "ERROR: ejecuta gh auth login"
  exit 1
}
 
echo "======================================"
echo " Preparando tablero: $PROJECT"
echo " Repositorio: $REPO"
echo "======================================"
 
# Verificar que el issue #1 sea el que queremos conservar.
TITULO_ISSUE_1="$(gh issue view 1 --repo "$REPO" --json title --jq '.title')"
 
if [[ "$TITULO_ISSUE_1" != "Sacar secretos del docker-compose y README" ]]; then
  echo "ERROR: el issue #1 no tiene el titulo esperado."
  echo "Encontrado: $TITULO_ISSUE_1"
  exit 1
fi
 
# Crear etiquetas
echo
echo "==> Creando etiquetas"
 
crear_label() {
  gh label create "$1" --repo "$REPO" \
    --color "$2" --description "$3" --force >/dev/null
  echo "    OK: $1"
}
 
crear_label "infra" "5319e7" "Infraestructura como codigo (Terraform, AWS)"
crear_label "seguridad" "d73a4a" "DevSecOps, secretos, escaneos"
crear_label "ci-cd" "0e8a16" "Pipelines de integracion y despliegue"
crear_label "testing" "fbca04" "Pruebas y calidad de codigo"
crear_label "observabilidad" "1d76db" "Metricas, logs, dashboards y alertas"
crear_label "docs" "c5def5" "Documentacion, diagramas, ADRs, tablero"
crear_label "docker" "0db7ed" "Imagenes y contenedores"
 
# Buscar un elemento dentro del Project.
buscar_item() {
  local url="$1"
 
  gh project item-list "$PROJECT_NUMBER" \
    --owner "$OWNER" --format json |
    jq -r --arg url "$url" \
      '.items[]? | select(.content.url == $url) | .id' |
    head -n 1
}
 
#
# Agregar un issue al Project y asignarle estado cuando corresponda.
asegurar_en_project() {
  local url="$1"
  local estado="${2:-}"
  local forzar="${3:-false}"
  local item_id=""
  local agregado=false
  local option_id=""
 
  item_id="$(buscar_item "$url")"
 
  if [[ -z "$item_id" ]]; then
    echo "    Agregando al Project: $url"
 
    gh project item-add "$PROJECT_NUMBER" \
      --owner "$OWNER" --url "$url" >/dev/null
 
    agregado=true
 
    # Esperar a que GitHub refleje el nuevo item en el Project.
    for intento in {1..10}; do
      item_id="$(buscar_item "$url")"
 
      if [[ -n "$item_id" ]]; then
        break
      fi
 
      echo "    Esperando que GitHub actualice el Project... ($intento/10)"
      sleep 2
    done
  fi
 
  if [[ -z "$item_id" ]]; then
    echo "ERROR: no se pudo obtener el ID del item: $url"
    return 1
  fi
 
  case "$estado" in
    "BackLog") option_id="$BACKLOG_ID" ;;
    "Todo") option_id="$TODO_ID" ;;
    "In Progress") option_id="$IN_PROGRESS_ID" ;;
    "In Review") option_id="$IN_REVIEW_ID" ;;
    "Done") option_id="$DONE_ID" ;;
    "") return 0 ;;
    *)
      echo "ERROR: estado desconocido: $estado"
      return 1
      ;;
  esac
 
  # No reiniciar el estado de issues que ya estaban en el tablero.
  if [[ "$agregado" == true || "$forzar" == true ]]; then
    gh project item-edit \
      --project-id "$PROJECT_ID" \
      --id "$item_id" \
      --field-id "$STATUS_FIELD_ID" \
      --single-select-option-id "$option_id" >/dev/null
 
    echo "    Estado asignado: $estado"
  fi
}
 
 
# Crear un issue o reutilizarlo si ya existe.
# Uso: crear_issue titulo label cuerpo [cerrar]
crear_issue() {
  local titulo="$1"
  local label="$2"
  local cuerpo="$3"
  local cerrar="${4:-}"
  local url
  local nuevo=false
  local estado="Todo"
  local forzar=false
 
  url="$(gh issue list --repo "$REPO" \
    --state all --limit 500 --json title,url |
    jq -r --arg titulo "$titulo" \
      '.[] | select(.title == $titulo) | .url' |
    head -n 1)"
 
  if [[ -z "$url" ]]; then
    echo "    Creando: $titulo"
 
    url="$(gh issue create \
      --repo "$REPO" \
      --title "$titulo" \
      --label "$label" \
      --body "$cuerpo")"
 
    nuevo=true
  else
    echo "    Ya existe: $titulo"
  fi
 
  if [[ "$cerrar" == "cerrar" ]]; then
    local issue_state
 
    issue_state="$(gh issue view "$url" --repo "$REPO" \
      --json state --jq '.state')"
 
    if [[ "$issue_state" != "CLOSED" ]]; then
      gh issue close "$url" --reason completed >/dev/null
    fi
 
    estado="Done"
    forzar=true
    echo "    Tarea completada: $titulo"
  fi
 
  asegurar_en_project "$url" "$estado" \
    "$([[ "$nuevo" == true || "$forzar" == true ]] && echo true || echo false)"
}
 
# Reutilizar el issue #1 sin modificar su titulo, cuerpo ni estado.
echo
echo "==> Conservando issue #1"
asegurar_en_project "$EXISTING_SECRET_ISSUE"
echo "    Conservado: Sacar secretos del docker-compose y README"
echo "    Estado actual: BackLog"
 
echo
echo "==> Creando y agregando issues"
 
# ---------------- Organización ----------------
 
crear_issue "Repo del equipo y protección de main" "docs" \
"Repo propio del equipo con el código de Tero y protección de la rama principal.
 
- [x] Crear repo y subir el código
- [x] Agregar colaboradores
- [x] Ruleset en main: PR obligatorio, 1 aprobación, sin force push
- [x] Probar push directo rechazado (captura)" cerrar
 
crear_issue "Tablero, plantilla de PR y CONTRIBUTING" "docs" \
"- [ ] Tablero Kanban con columnas y automatizaciones
- [ ] .github/pull_request_template.md
- [ ] CONTRIBUTING.md con convenciones de ramas, commits y revisión"
 
crear_issue "Capturas del tablero (inicio, mitad, cierre)" "docs" \
"Guardar en docs/tablero/ con fecha en el nombre.
 
- [ ] Captura inicio
- [ ] Captura mitad (~15/11)
- [ ] Captura cierre (antes de la auditoría)"
 
# ---------------- Secretos y contenedores ----------------
# El issue de secretos ya existe (#1), por eso no se crea otro.
 
crear_issue "Dockerfiles optimizados: servicios Go (catalog, orders)" "docker" \
"- [ ] Multi-stage
- [ ] Imagen base mínima
- [ ] Usuario no-root
- [ ] .dockerignore
- [ ] Verificar que levanta con docker compose"
 
crear_issue "Dockerfiles optimizados: servicios Node (ui, admin, checkout)" "docker" \
"- [ ] Generar package-lock.json en ui y admin (builds reproducibles)
- [ ] Multi-stage, imagen base mínima, usuario no-root
- [ ] .dockerignore
- [ ] checkout con Yarn 4 (install inmutable)
- [ ] Verificar que levanta con docker compose"
 
crear_issue "Dockerfile optimizado: cart (Python)" "docker" \
"- [ ] Multi-stage
- [ ] Imagen base mínima
- [ ] Usuario no-root
- [ ] .dockerignore
- [ ] Verificar que levanta con docker compose"
 
crear_issue "Quitar puertos de DB/Redis y versionar imágenes" "docker" \
"- [ ] DB y Redis sin puertos publicados en el host
- [ ] Labels de versión y SHA en las imágenes
- [ ] Evidencia antes/después: tamaño de imágenes y usuario (capturas)"
 
# ---------------- CI/CD ----------------
 
crear_issue "Workflow de CI en PRs" "ci-cd" \
"- [ ] Workflow que corre en cada PR (build de los servicios)
- [ ] Integrar los jobs de calidad y seguridad
- [ ] Activar status checks obligatorios en el ruleset de main"
 
crear_issue "Publicación de imágenes en ECR" "ci-cd" \
"- [ ] Login a ECR desde GitHub Actions (secrets / OIDC)
- [ ] Tag por SHA del commit
- [ ] Push solo si pasa el escaneo de la imagen"
 
crear_issue "CD con promoción Dev → Test → Prod" "ci-cd" \
"- [ ] GitHub Environments: dev, test, prod
- [ ] Deploy automático a Dev al mergear a main
- [ ] Promoción a Test solo si pasan los tests y quality gates
- [ ] Aprobación manual (required reviewers) para Prod
- [ ] Misma imagen (mismo SHA) en los tres ambientes"
 
# ---------------- Calidad y seguridad ----------------
 
crear_issue "Tests de integración con Newman en el pipeline" "testing" \
"- [ ] Colección Postman con un par de tests (carrito → checkout → orden)
- [ ] Ejecutar con Newman contra Dev en el pipeline
- [ ] Si falla, no se promueve a Test"
 
crear_issue "Análisis estático y quality gate" "testing" \
"- [ ] Elegir herramienta (SonarCloud / linters / Semgrep)
- [ ] Integrar en el CI
- [ ] Definir y documentar umbrales (bugs, vulnerabilidades, duplicación, code smells)"
 
crear_issue "Secret scanning: Gitleaks en el CI" "seguridad" \
"- [ ] Job de Gitleaks que falle el build si detecta secretos
- [ ] Escaneo del historial completo una vez y documentar resultado
- [ ] Activar secret scanning + push protection de GitHub"
 
crear_issue "SCA y escaneo de imágenes con Trivy" "seguridad" \
"- [ ] Trivy fs sobre dependencias de los 6 servicios
- [ ] Gate: bloquear CRITICAL/HIGH (confirmar criterio de 'sin parche' con el docente)
- [ ] Trivy image antes de publicar en el registry"
 
crear_issue "SAST con Semgrep" "seguridad" \
"- [ ] Integrar Semgrep en el CI
- [ ] Revisar hallazgos iniciales"
 
crear_issue "Informe de calidad y hallazgos de seguridad" "docs" \
"- [ ] Párrafo de interpretación de resultados de calidad y recomendaciones
- [ ] Hallazgos de seguridad: remediaciones aplicadas
- [ ] Excepciones justificadas (.trivyignore comentado)"
 
# ---------------- Infraestructura ----------------
 
crear_issue "Bucket S3 y backend remoto de Terraform" "infra" \
"- [ ] Crear bucket del state a mano (versionado, cifrado, sin acceso público)
- [ ] Backend S3 con locking
- [ ] Una key de state por ambiente"
 
crear_issue "Módulo de red" "infra" \
"- [ ] VPC, subredes públicas y privadas
- [ ] Security groups (DB y Redis solo accesibles desde ECS)"
 
crear_issue "Módulo ecs-service + cluster, ECR y ALB" "infra" \
"- [ ] Módulo reutilizable: task definition + service + target group
- [ ] Cluster ECS (Fargate)
- [ ] Repositorios ECR (tags inmutables, scan on push)
- [ ] ALB"
 
crear_issue "DB, Redis y secretos en AWS" "infra" \
"- [ ] RDS PostgreSQL (password gestionada por AWS, fuera del state)
- [ ] Redis (ElastiCache o task en subred privada)
- [ ] Secretos en Secrets Manager / SSM referenciados desde las task definitions"
 
crear_issue "tfvars por ambiente y outputs documentados" "infra" \
"- [ ] dev.tfvars, test.tfvars, prod.tfvars
- [ ] Outputs con description (URL del ALB, endpoints, repos ECR)"
 
crear_issue "Lambda de notificaciones" "infra" \
"Propósito: seguridad / observabilidad.
 
- [ ] Definir el evento (alarma de CloudWatch vía SNS, o hallazgos de ECR vía EventBridge)
- [ ] Lambda que formatea y notifica (mail / Slack / Discord)
- [ ] Todo definido en Terraform"
 
# ---------------- Observabilidad ----------------
 
crear_issue "Logs, métricas y dashboard" "observabilidad" \
"- [ ] Logs de todos los servicios en CloudWatch (awslogs, un log group por servicio)
- [ ] Logs en formato estructurado (JSON) + queries de Logs Insights
- [ ] Container Insights (CPU, memoria, red)
- [ ] Dashboard en Terraform
- [ ] (Bonus) Recolectar métricas /metrics existentes"
 
crear_issue "Alertas y runbooks" "observabilidad" \
"- [ ] Alerta de disponibilidad (hosts unhealthy) + runbook
- [ ] Alerta de errores/latencia (5xx o p95) + runbook
- [ ] Notificación vía SNS / Lambda"
 
# ---------------- Documentación ----------------
 
crear_issue "README, diagramas, ADRs y lecciones aprendidas" "docs" \
"- [ ] README completo (prerrequisitos, variables, deploy, rollback)
- [ ] Diagrama de arquitectura
- [ ] Diagrama del pipeline CI/CD con etapas de seguridad
- [ ] Diagrama del modelo de ramas (GitHub Flow)
- [ ] ADRs de las decisiones principales
- [ ] Lecciones aprendidas"
 
crear_issue "Ensayo de la demo de auditoría" "docs" \
"- [ ] Recorrer cada control del checklist con su evidencia
- [ ] Verificar que alguien externo pueda seguir el README"
 
echo
echo "======================================"
echo " Proceso finalizado."
echo " Project: $PROJECT"
echo " Issue #1 conservado en BackLog."
echo " Issues nuevos: Todo."
echo " Issue de main: Done."
echo "======================================"