#!/usr/bin/env bash
# ------------------------------------------------------------------
# Resumen legible de vulnerabilidades con Trivy.
#
# Escanea las dependencias del repo (fs) y las 6 imágenes Docker, y genera
# un archivo Markdown con UNA FILA POR LIBRERÍA: versión actual, a qué versión
# actualizar, cuántas vulnerabilidades corrige y qué hacer.
#
# Uso (desde la raíz del repo, con las imágenes ya construidas):
#   ./scripts/trivy-resumen.sh                 -> genera trivy-resumen.md
#   ./scripts/trivy-resumen.sh mi-archivo.md   -> otro nombre de salida
#
# Requisitos: Docker y python3.
# ------------------------------------------------------------------
set -euo pipefail

TRIVY_IMAGE="aquasec/trivy:0.57.0"
PREFIJO_IMAGEN="devops-tero-2026"
SERVICIOS="ui catalog carts orders checkout admin"
SALIDA="${1:-trivy-resumen.md}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

trivy() {
  docker run --rm \
    -v "$PWD":/src \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v trivy-cache:/root/.cache/ \
    "$TRIVY_IMAGE" "$@" --scanners vuln --severity HIGH,CRITICAL --format json --quiet
}

echo "==> Escaneando dependencias del repo (fs)..."
trivy fs /src > "$TMP/fs.json"

for s in $SERVICIOS; do
  echo "==> Escaneando imagen $PREFIJO_IMAGEN-$s..."
  trivy image "$PREFIJO_IMAGEN-$s" > "$TMP/image-$s.json"
done

echo "==> Generando resumen en $SALIDA"
python3 - "$TMP" "$SALIDA" "$SERVICIOS" <<'PY'
import json, re, sys, os

tmp, salida, servicios = sys.argv[1], sys.argv[2], sys.argv[3].split()

def ver(v):
    """Convierte '1:2.41.5-0+deb13u1' o 'v1.24.13' en una tupla comparable."""
    v = re.sub(r'^\d+:', '', v or '').lstrip('v')
    return tuple(int(n) for n in re.findall(r'\d+', v)[:4])

def elegir_fix(instalada, fixed):
    """De '5.0.10, 3.0.7, 2.1.5' elige la versión de la misma rama que la instalada."""
    cands = [c.strip() for c in (fixed or '').split(',') if c.strip()]
    if not cands:
        return None
    vi = ver(instalada)
    misma_rama = [c for c in cands if ver(c)[:1] == vi[:1] and ver(c) > vi]
    if misma_rama:
        return min(misma_rama, key=ver)
    mayores = [c for c in cands if ver(c) > vi]
    return min(mayores, key=ver) if mayores else cands[0]

def que_hacer(clase, tipo, lib, fix, servicio):
    if fix is None:
        return "Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante"
    if clase == "os-pkgs":
        return "Paquete del sistema de la imagen base: reconstruir con `docker compose build --pull`"
    if lib == "stdlib":
        return f"Es el propio Go: compilar con Go >= {fix} (cambiar el FROM golang del Dockerfile)"
    if tipo in ("gomod", "gobinary"):
        return f"`go get {lib}@v{fix.lstrip('v')}` + `go mod tidy`"
    if tipo in ("yarn", "node-pkg", "npm"):
        return f"`yarn up -R {lib}` (o actualizar el paquete que la trae)" if servicio == "checkout" \
            else f"Actualizar `{lib}` (npm update / package.json)"
    if tipo in ("pip", "python-pkg", "poetry", "pipenv"):
        return f"Subir `{lib}` (o la librería que la trae) en requirements.txt a >= {fix}"
    return f"Actualizar a {fix}"

def resumir(path, servicio=None):
    with open(path) as f:
        data = json.load(f)
    filas = {}
    for r in data.get("Results") or []:
        for v in r.get("Vulnerabilities") or []:
            lib = v["PkgName"]
            key = (r.get("Target"), lib)
            fix = elegir_fix(v.get("InstalledVersion"), v.get("FixedVersion"))
            fila = filas.setdefault(key, {
                "target": r.get("Target"), "clase": r.get("Class"), "tipo": r.get("Type"),
                "lib": lib, "instalada": v.get("InstalledVersion"),
                "fix": None, "sin_fix": 0, "critical": 0, "high": 0, "cves": []})
            fila["cves"].append(v["VulnerabilityID"])
            fila["critical" if v["Severity"] == "CRITICAL" else "high"] += 1
            if fix is None:
                fila["sin_fix"] += 1
            elif fila["fix"] is None or ver(fix) > ver(fila["fix"]):
                fila["fix"] = fix
    return list(filas.values())

def tabla(filas, servicio):
    if not filas:
        return "✅ Sin vulnerabilidades HIGH/CRITICAL.\n"
    filas.sort(key=lambda f: (-f["critical"], -(f["critical"] + f["high"]), f["lib"]))
    out = ["| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |",
           "|---|---|---|---|---|---|---|"]
    for f in filas:
        fix = f["fix"] or "—"
        accion = que_hacer(f["clase"], f["tipo"], f["lib"], f["fix"], servicio)
        out.append(f"| `{f['lib']}` | {f['instalada']} | {fix} | {f['critical'] or ''} | "
                   f"{f['high'] or ''} | {f['sin_fix'] or ''} | {accion} |")
    return "\n".join(out) + "\n"

def totales(filas):
    c = sum(f["critical"] for f in filas); h = sum(f["high"] for f in filas)
    s = sum(f["sin_fix"] for f in filas)
    return c, h, s

md = ["# Resumen de vulnerabilidades (Trivy)", "",
      "Solo severidades HIGH y CRITICAL. Una fila por librería; "
      "**Actualizar a** es la versión mínima que corrige todas sus vulnerabilidades.", ""]

# Resumen general
md += ["## Totales", "", "| Análisis | CRITICAL | HIGH | Sin arreglo (no bloquean con --ignore-unfixed) |",
       "|---|---|---|---|"]
secciones = []
fs = resumir(os.path.join(tmp, "fs.json"))
c, h, s = totales(fs); md.append(f"| Dependencias del repo (fs) | {c} | {h} | {s} |")
for srv in servicios:
    filas = resumir(os.path.join(tmp, f"image-{srv}.json"), srv)
    c, h, s = totales(filas); md.append(f"| Imagen `{srv}` | {c} | {h} | {s} |")
    secciones.append((srv, filas))
md.append("")

# Detalle de fs agrupado por archivo
md += ["## Dependencias del repo (trivy fs)", ""]
por_archivo = {}
for f in fs:
    por_archivo.setdefault(f["target"], []).append(f)
if not por_archivo:
    md.append("✅ Sin vulnerabilidades HIGH/CRITICAL.\n")
for target, filas in sorted(por_archivo.items()):
    srv = target.split("/")[1] if target.startswith("src/") else None
    md += [f"### `{target}`", "", tabla(filas, srv)]

# Detalle por imagen
md += ["## Imágenes Docker (trivy image)", ""]
for srv, filas in secciones:
    md += [f"### Imagen `{srv}`", "", tabla(filas, srv)]

with open(salida, "w") as f:
    f.write("\n".join(md))
print(f"Listo: {salida}")
PY