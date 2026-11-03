# Tero - Aplicación de ejemplo

Tero es una tienda en línea basada en microservicios. Permite explorar un catálogo de productos por categoría, gestionar un carrito de compras, realizar el checkout y consultar órdenes. Incluye un panel de administración para gestionar productos y ver órdenes.

> Los nombres técnicos (servicios `catalog`, `carts`, `orders`, `checkout`, variables `RETAIL_*`, usuario de base de datos `retail_user`) se mantienen tal como los dejó el equipo de desarrollo original.

## Requisitos previos

- [Docker](https://docs.docker.com/get-docker/) 24+
- [Docker Compose](https://docs.docker.com/compose/install/) v2.20+

## Inicio rápido

Clonar el repositorio y ubicarse en el directorio `app/`.

Crear el archivo local de variables de entorno a partir del ejemplo:

```bash
cp .env.example .env
```

Editar el archivo `.env` y configurar las credenciales correspondientes para la base de datos y el panel de administración.

Luego, iniciar los servicios:

```bash
docker compose up --build
```

Una vez iniciados, la aplicación estará disponible en:

| Servicio | URL                                            |
| -------- | ---------------------------------------------- |
| Tienda   | [http://localhost:8080](http://localhost:8080) |
| Admin    | [http://localhost:8081](http://localhost:8081) |

Las credenciales del panel de administración se configuran mediante las variables de entorno definidas en el archivo `.env`.

**Importante:** el archivo `.env` contiene información sensible y no debe subirse al repositorio. Para evitarlo, está incluido en `.gitignore`. El archivo `.env.example` contiene únicamente valores de referencia.

## Comandos útiles

```bash
# Detener los servicios
docker compose down

# Detener y eliminar volúmenes (resetear base de datos)
docker compose down -v

# Reconstruir un servicio específico
docker compose up --build <servicio>

# Ver logs de un servicio
docker compose logs -f <servicio>
```

---

## Arquitectura de microservicios

```text
          ┌──────────────────────────────────────────────────┐
          │               Usuario / Navegador                 │
          └────────────────────────┬─────────────────────────┘
                                   │ HTTP
          ┌────────────────────────▼─────────────────────────┐
          │                   UI :8080                       │
          │             Node.js 22 / Express                  │
          └───────┬──────────┬──────────┬────────────┬───────┘
                  │          │          │            │ HTTP (proxy)
        ┌─────────▼────┐ ┌───▼─────┐ ┌──▼────────┐ ┌▼──────────┐
        │   Catalog    │ │  Cart   │ │ Checkout  │ │  Orders   │
        │    :8080     │ │  :8080  │ │  :8080    │ │  :8080    │
        │  Go / Gin    │ │ Python  │ │ NestJS/TS │ │ Go / Gin  │
        └──────┬───────┘ └────┬────┘ └─────┬─────┘ └─────┬─────┘
               │              │            │             │
               │              │            │ HTTP        │
               │              │      ┌─────▼───────┐     │
               │              │      │   Redis 7   │◄────┤
               │              │      └─────────────┘     │
               └──────────────┴───────────────────────────┘
                                          │
        ┌─────────────────────────────────▼──────────────────────┐
        │                     PostgreSQL 16                      │
        │          catalogdb       cartdb         orders          │
        └────────────────────────────────────────────────────────┘

          ┌──────────────────────────────────────────────────┐
          │                  Admin :8081                     │
          │             Node.js 22 / Express                  │
          └────────────────────────┬─────────────────────────┘
                                   │ SQL directo
          ┌────────────────────────▼─────────────────────────┐
          │                  PostgreSQL 16                   │
          └──────────────────────────────────────────────────┘
```

### Flujo de comunicación

| Origen   | Destino    | Protocolo | Descripción                            |
| -------- | ---------- | --------- | -------------------------------------- |
| UI       | Catalog    | HTTP REST | Listar y consultar productos           |
| UI       | Cart       | HTTP REST | Agregar, quitar y consultar carrito    |
| UI       | Checkout   | HTTP REST | Iniciar y confirmar el proceso de pago |
| UI       | Orders     | HTTP REST | Consultar historial de órdenes         |
| Checkout | Orders     | HTTP REST | Crear orden al confirmar checkout      |
| Checkout | Redis      | TCP       | Persistencia de sesión de checkout     |
| Catalog  | PostgreSQL | TCP       | Base de datos `catalogdb`              |
| Cart     | PostgreSQL | TCP       | Base de datos `cartdb`                 |
| Orders   | PostgreSQL | TCP       | Base de datos `orders`                 |
| Admin    | PostgreSQL | TCP       | Acceso directo a todas las bases       |

---

## Tecnologías por servicio

| Servicio     | Lenguaje    | Framework     | Runtime      | Persistencia | Puerto externo |
| ------------ | ----------- | ------------- | ------------ | ------------ | -------------- |
| **ui**       | TypeScript  | Express       | Node.js 22   | —            | 8080           |
| **catalog**  | Go 1.24     | Gin + GORM    | Alpine Linux | PostgreSQL   | —              |
| **cart**     | Python 3.12 | FastAPI       | Python slim  | PostgreSQL   | —              |
| **checkout** | TypeScript  | NestJS        | Node.js 22   | Redis        | —              |
| **orders**   | Go 1.24     | Gin + GORM    | Alpine Linux | PostgreSQL   | —              |
| **admin**    | TypeScript  | Express       | Node.js 22   | PostgreSQL   | 8081           |
| **db**       | —           | PostgreSQL 16 | —            | —            | —              |
| **redis**    | —           | Redis 7       | Alpine Linux | —            | —              |

### Dependencias clave

| Servicio     | Dependencias destacadas                                         |
| ------------ | --------------------------------------------------------------- |
| **catalog**  | `gin-gonic/gin`, `gorm`, `go-gorm/postgres`, OpenTelemetry      |
| **cart**     | `FastAPI`, `Uvicorn`, `Pydantic`, `psycopg2`, Prometheus client |
| **checkout** | `NestJS`, `ioredis`, `class-validator`, OpenTelemetry           |
| **orders**   | `gin-gonic/gin`, `gorm`, `go-gorm/postgres`, Prometheus         |
| **ui**       | `express`, `http-proxy-middleware`                              |
| **admin**    | `express`, `pg`, `jsonwebtoken`, `cookie-parser`                |

---

## Variables de entorno

Las variables de entorno permiten configurar los servicios sin incluir credenciales directamente en los archivos del repositorio.

### UI

| Variable                       | Descripción               | Configuración          |
| ------------------------------ | ------------------------- | ---------------------- |
| `RETAIL_UI_ENDPOINTS_CATALOG`  | URL del servicio catalog  | `http://catalog:8080`  |
| `RETAIL_UI_ENDPOINTS_CARTS`    | URL del servicio cart     | `http://carts:8080`    |
| `RETAIL_UI_ENDPOINTS_CHECKOUT` | URL del servicio checkout | `http://checkout:8080` |
| `RETAIL_UI_ENDPOINTS_ORDERS`   | URL del servicio orders   | `http://orders:8080`   |

### Catalog / Orders / Cart

| Variable                              | Descripción              | Configuración |
| ------------------------------------- | ------------------------ | ------------- |
| `RETAIL_CATALOG_PERSISTENCE_PROVIDER` | Tipo de persistencia     | `postgres`    |
| `RETAIL_CATALOG_PERSISTENCE_ENDPOINT` | Host:Puerto de la DB     | `db:5432`     |
| `POSTGRES_USER`                       | Usuario de PostgreSQL    | `.env`        |
| `POSTGRES_PASSWORD`                   | Contraseña de PostgreSQL | `.env`        |

### Checkout

| Variable                                | Descripción             | Configuración        |
| --------------------------------------- | ----------------------- | -------------------- |
| `RETAIL_CHECKOUT_PERSISTENCE_PROVIDER`  | Tipo de persistencia    | `redis`              |
| `RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL` | URL de Redis            | `redis://redis:6379` |
| `RETAIL_CHECKOUT_ENDPOINTS_ORDERS`      | URL del servicio orders | `http://orders:8080` |

### Admin

| Variable           | Descripción              | Configuración |
| ------------------ | ------------------------ | ------------- |
| `ADMIN_USERNAME`   | Usuario administrador    | `.env`        |
| `ADMIN_PASSWORD`   | Contraseña administrador | `.env`        |
| `ADMIN_JWT_SECRET` | Secreto para tokens JWT  | `.env`        |

---

## Estructura del repositorio

```text
app/
├── .env.example       # Plantilla de variables de entorno
├── .gitignore         # Exclusión de archivos locales y sensibles
├── docker-compose.yml
├── init-db.sql
└── src/
    ├── catalog/       # Go - Catálogo de productos
    ├── cart/          # Python - Carrito de compras
    ├── checkout/      # TypeScript/NestJS - Proceso de pago
    ├── orders/        # Go - Gestión de órdenes
    ├── ui/            # TypeScript/Express - Frontend
    └── admin/         # TypeScript/Express - Panel de administración
```
