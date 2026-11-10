# Resumen de vulnerabilidades (Trivy)

Solo severidades HIGH y CRITICAL. Una fila por librería; **Actualizar a** es la versión mínima que corrige todas sus vulnerabilidades.

## Totales

| Análisis | CRITICAL | HIGH | Sin arreglo (no bloquean con --ignore-unfixed) |
|---|---|---|---|
| Dependencias del repo (fs) | 6 | 69 | 0 |
| Imagen `ui` | 1 | 6 | 0 |
| Imagen `catalog` | 3 | 49 | 0 |
| Imagen `carts` | 0 | 52 | 47 |
| Imagen `orders` | 2 | 43 | 0 |
| Imagen `checkout` | 2 | 29 | 0 |
| Imagen `admin` | 1 | 6 | 0 |

## Dependencias del repo (trivy fs)

### `src/catalog/go.mod`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `github.com/jackc/pgx/v5` | v5.6.0 | 5.9.0 | 2 |  |  | `go get github.com/jackc/pgx/v5@v5.9.0` + `go mod tidy` |
| `google.golang.org/grpc` | v1.73.0 | 1.83.1 | 1 | 3 |  | `go get google.golang.org/grpc@v1.83.1` + `go mod tidy` |
| `golang.org/x/crypto` | v0.45.0 | 0.55.0 |  | 10 |  | `go get golang.org/x/crypto@v0.55.0` + `go mod tidy` |
| `golang.org/x/net` | v0.47.0 | 0.62.0 |  | 7 |  | `go get golang.org/x/net@v0.62.0` + `go mod tidy` |
| `go.opentelemetry.io/otel/sdk` | v1.37.0 | 1.43.0 |  | 2 |  | `go get go.opentelemetry.io/otel/sdk@v1.43.0` + `go mod tidy` |
| `golang.org/x/text` | v0.31.0 | 0.41.0 |  | 2 |  | `go get golang.org/x/text@v0.41.0` + `go mod tidy` |
| `github.com/klauspost/compress` | v1.17.11 | 1.18.7 |  | 1 |  | `go get github.com/klauspost/compress@v1.18.7` + `go mod tidy` |
| `go.opentelemetry.io/otel` | v1.37.0 | 1.41.0 |  | 1 |  | `go get go.opentelemetry.io/otel@v1.41.0` + `go mod tidy` |

### `src/checkout/yarn.lock`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `proxy-addr` | 2.0.7 | 2.0.8 | 1 |  |  | `yarn up -R proxy-addr` (o actualizar el paquete que la trae) |
| `multer` | 2.0.1 | 2.5.0 |  | 8 |  | `yarn up -R multer` (o actualizar el paquete que la trae) |
| `brace-expansion` | 2.0.2 | 2.1.6 |  | 5 |  | `yarn up -R brace-expansion` (o actualizar el paquete que la trae) |
| `js-yaml` | 4.1.0 | 4.3.2 |  | 3 |  | `yarn up -R js-yaml` (o actualizar el paquete que la trae) |
| `minimatch` | 10.0.1 | 10.2.3 |  | 3 |  | `yarn up -R minimatch` (o actualizar el paquete que la trae) |
| `body-parser` | 2.2.2 | 2.4.0 |  | 1 |  | `yarn up -R body-parser` (o actualizar el paquete que la trae) |
| `glob` | 11.0.1 | 11.1.0 |  | 1 |  | `yarn up -R glob` (o actualizar el paquete que la trae) |
| `lodash` | 4.17.21 | 4.18.0 |  | 1 |  | `yarn up -R lodash` (o actualizar el paquete que la trae) |
| `path-to-regexp` | 8.2.0 | 8.4.0 |  | 1 |  | `yarn up -R path-to-regexp` (o actualizar el paquete que la trae) |

### `src/orders/go.mod`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `github.com/jackc/pgx/v5` | v5.6.0 | 5.9.0 | 2 |  |  | `go get github.com/jackc/pgx/v5@v5.9.0` + `go mod tidy` |
| `golang.org/x/crypto` | v0.41.0 | 0.55.0 |  | 11 |  | `go get golang.org/x/crypto@v0.55.0` + `go mod tidy` |
| `golang.org/x/net` | v0.43.0 | 0.62.0 |  | 7 |  | `go get golang.org/x/net@v0.62.0` + `go mod tidy` |
| `golang.org/x/text` | v0.28.0 | 0.41.0 |  | 2 |  | `go get golang.org/x/text@v0.41.0` + `go mod tidy` |

## Imágenes Docker (trivy image)

### Imagen `ui`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `libssl3` | 3.0.18-1~deb12u2 | 3.0.22-1~deb12u2 | 1 | 6 |  | Paquete del sistema de la imagen base: reconstruir con `docker compose build --pull` |

### Imagen `catalog`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `github.com/jackc/pgx/v5` | v5.6.0 | 5.9.0 | 2 |  |  | `go get github.com/jackc/pgx/v5@v5.9.0` + `go mod tidy` |
| `google.golang.org/grpc` | v1.73.0 | 1.83.1 | 1 | 3 |  | `go get google.golang.org/grpc@v1.83.1` + `go mod tidy` |
| `stdlib` | v1.24.13 | 1.26.10 |  | 23 |  | Es el propio Go: compilar con Go >= 1.26.10 (cambiar el FROM golang del Dockerfile) |
| `golang.org/x/crypto` | v0.45.0 | 0.55.0 |  | 10 |  | `go get golang.org/x/crypto@v0.55.0` + `go mod tidy` |
| `golang.org/x/net` | v0.47.0 | 0.62.0 |  | 7 |  | `go get golang.org/x/net@v0.62.0` + `go mod tidy` |
| `go.opentelemetry.io/otel/sdk` | v1.37.0 | 1.43.0 |  | 2 |  | `go get go.opentelemetry.io/otel/sdk@v1.43.0` + `go mod tidy` |
| `golang.org/x/text` | v0.31.0 | 0.41.0 |  | 2 |  | `go get golang.org/x/text@v0.41.0` + `go mod tidy` |
| `github.com/klauspost/compress` | v1.17.11 | 1.18.7 |  | 1 |  | `go get github.com/klauspost/compress@v1.18.7` + `go mod tidy` |
| `go.opentelemetry.io/otel` | v1.37.0 | 1.41.0 |  | 1 |  | `go get go.opentelemetry.io/otel@v1.41.0` + `go mod tidy` |

### Imagen `carts`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `bsdutils` | 1:2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libblkid1` | 2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `liblastlog2-2` | 2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libmount1` | 2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libsmartcols1` | 2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libuuid1` | 2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `login` | 1:4.16.0-2+really2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `mount` | 2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `util-linux` | 2.41.5-0+deb13u1 | — |  | 4 | 4 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libsqlite3-0` | 3.46.1-7+deb13u2 | — |  | 3 | 3 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `starlette` | 0.38.6 | 1.3.1 |  | 3 |  | Subir `starlette` (o la librería que la trae) en requirements.txt a >= 1.3.1 |
| `zlib1g` | 1:1.3.dfsg+really1.3.1-1+b1 | 1:1.3.dfsg+really1.3.1-1+deb13u1 |  | 2 |  | Paquete del sistema de la imagen base: reconstruir con `docker compose build --pull` |
| `libacl1` | 2.3.2-2+b1 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libncursesw6` | 6.5+20250216-2 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libsystemd0` | 257.13-1~deb13u1 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libtinfo6` | 6.5+20250216-2 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `libudev1` | 257.13-1~deb13u1 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `ncurses-base` | 6.5+20250216-2 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `ncurses-bin` | 6.5+20250216-2 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |
| `perl-base` | 5.40.1-6+deb13u1 | — |  | 1 | 1 | Sin arreglo publicado todavía: excepción (--ignore-unfixed), revisar más adelante |

### Imagen `orders`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `github.com/jackc/pgx/v5` | v5.6.0 | 5.9.0 | 2 |  |  | `go get github.com/jackc/pgx/v5@v5.9.0` + `go mod tidy` |
| `stdlib` | v1.24.13 | 1.26.10 |  | 23 |  | Es el propio Go: compilar con Go >= 1.26.10 (cambiar el FROM golang del Dockerfile) |
| `golang.org/x/crypto` | v0.41.0 | 0.55.0 |  | 11 |  | `go get golang.org/x/crypto@v0.55.0` + `go mod tidy` |
| `golang.org/x/net` | v0.43.0 | 0.62.0 |  | 7 |  | `go get golang.org/x/net@v0.62.0` + `go mod tidy` |
| `golang.org/x/text` | v0.28.0 | 0.41.0 |  | 2 |  | `go get golang.org/x/text@v0.41.0` + `go mod tidy` |

### Imagen `checkout`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `libssl3` | 3.0.18-1~deb12u2 | 3.0.22-1~deb12u2 | 1 | 6 |  | Paquete del sistema de la imagen base: reconstruir con `docker compose build --pull` |
| `proxy-addr` | 2.0.7 | 2.0.8 | 1 |  |  | `yarn up -R proxy-addr` (o actualizar el paquete que la trae) |
| `multer` | 2.0.1 | 2.5.0 |  | 8 |  | `yarn up -R multer` (o actualizar el paquete que la trae) |
| `brace-expansion` | 2.0.2 | 2.1.6 |  | 5 |  | `yarn up -R brace-expansion` (o actualizar el paquete que la trae) |
| `js-yaml` | 4.1.0 | 4.3.2 |  | 3 |  | `yarn up -R js-yaml` (o actualizar el paquete que la trae) |
| `minimatch` | 10.0.1 | 10.2.3 |  | 3 |  | `yarn up -R minimatch` (o actualizar el paquete que la trae) |
| `body-parser` | 2.2.2 | 2.4.0 |  | 1 |  | `yarn up -R body-parser` (o actualizar el paquete que la trae) |
| `glob` | 11.0.1 | 11.1.0 |  | 1 |  | `yarn up -R glob` (o actualizar el paquete que la trae) |
| `lodash` | 4.17.21 | 4.18.0 |  | 1 |  | `yarn up -R lodash` (o actualizar el paquete que la trae) |
| `path-to-regexp` | 8.2.0 | 8.4.0 |  | 1 |  | `yarn up -R path-to-regexp` (o actualizar el paquete que la trae) |

### Imagen `admin`

| Librería | Versión actual | Actualizar a | CRITICAL | HIGH | Sin arreglo | Qué hacer |
|---|---|---|---|---|---|---|
| `libssl3` | 3.0.18-1~deb12u2 | 3.0.22-1~deb12u2 | 1 | 6 |  | Paquete del sistema de la imagen base: reconstruir con `docker compose build --pull` |
