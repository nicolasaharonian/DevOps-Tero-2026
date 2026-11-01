# Cómo contribuir a Tero

## Estrategia de ramas: GitHub Flow
- `main` es la única rama permanente y está protegida: no se permite push directo.
- Todo cambio entra por Pull Request desde una rama corta (1 a 3 días).
- Cada merge a `main` dispara el pipeline, que despliega en Dev → Test → Prod.

## Nombres de ramas
`<tipo>/<n°-de-issue>-<descripcion-corta>`

| Tipo | Uso | Ejemplo |
|---|---|---|
| `feature/` | Funcionalidad nueva | `feature/4-sacar-secretos` |
| `fix/` | Corrección de errores | `fix/12-healthcheck-orders` |
| `infra/` | Terraform / AWS | `infra/19-modulo-red` |
| `ci/` | Pipelines | `ci/9-workflow-pr` |
| `docs/` | Documentación | `docs/26-readme` |
| `chore/` | Mantenimiento, scripts | `chore/2-script-tablero` |

## Mensajes de commit
Formato [Conventional Commits](https://www.conventionalcommits.org/es/):
```
feat(catalog): dockerfile multi-stage con usuario no-root
fix(cart): corregir puerto en healthcheck
docs: agregar diagrama de arquitectura
```

## Flujo de trabajo
1. `git switch main && git pull`
2. `git switch -c feature/<n°>-<descripcion>`
3. Commits pequeños y descriptivos.
4. `git push -u origin <rama>`
5. Abrir el PR hacia `main` completando la plantilla (con `Closes #N`).
6. Asignar un revisor.
7. Squash and merge una vez aprobado.

## Reglas de revisión
- Se necesita **1 aprobación** de un integrante distinto al autor.
- Todos los comentarios deben quedar resueltos antes del merge.
- Si se agregan commits después de la aprobación, hay que volver a aprobar.
- Los checks del CI deben pasar (cuando estén activos).

## Seguridad
- Nunca commitear `.env`, contraseñas, tokens ni credenciales de AWS.
- Las variables locales van en `.env` (copiar desde `.env.example`).
- Los secretos del pipeline van en GitHub Secrets; los de la aplicación, en AWS Secrets Manager.