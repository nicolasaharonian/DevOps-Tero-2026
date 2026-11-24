# Tarea única que inicializa la base con init-db.sql.
#
# En docker compose, Postgres corría init-db.sql solo al arrancar por primera vez.
# RDS no hace eso: arranca solo con la base "orders". Esta tarea prende un
# contenedor de Postgres dentro de la VPC, corre el script contra RDS y se apaga.
#
# No es un servicio (no queda corriendo). Se ejecuta una vez a mano, después
# de crear RDS:
#   terraform output -raw init_db_command

# Cuaderno de logs: para ver qué hizo el script
resource "aws_cloudwatch_log_group" "init_db" {
  name              = "/ecs/${local.name}/init-db"
  retention_in_days = 7
}

# La receta
resource "aws_ecs_task_definition" "init_db" {
  family                   = "${local.name}-init-db"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab.arn
  task_role_arn            = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([
    {
      name      = "init-db"
      image     = "postgres:16-alpine" # trae psql, el cliente de Postgres
      essential = true

      # Le pasa el contenido de init-db.sql a psql
      command = ["sh", "-c", "printf '%s' \"$INIT_SQL\" | psql"]

      # A qué base conectarse (psql lee estas variables solo)
      environment = [
        { name = "PGHOST", value = module.database.address },
        { name = "PGPORT", value = tostring(module.database.port) },
        { name = "PGUSER", value = module.database.username },
        { name = "PGDATABASE", value = "orders" },
        { name = "INIT_SQL", value = file("${path.module}/../init-db.sql") },
      ]

      # La contraseña, desde Secrets Manager
      secrets = [
        { name = "PGPASSWORD", valueFrom = "${module.database.master_secret_arn}:password::" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.init_db.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "init-db"
        }
      }
    }
  ])
}