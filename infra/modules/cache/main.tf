# Módulo de caché: un nodo de ElastiCache Redis en las subredes privadas.
# Lo usa el servicio checkout para guardar los pedidos en curso.
# Igual que la base, solo es accesible desde las tareas de ECS (redis-sg).

# Grupo de subredes: en qué subredes (privadas) puede vivir el nodo
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis-subnets"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name}-redis-subnets"
  }
}

resource "aws_elasticache_cluster" "this" {
  cluster_id = "${var.name}-redis"

  engine          = "redis"
  engine_version  = var.engine_version
  node_type       = var.node_type
  num_cache_nodes = 1 # Redis en este recurso admite un solo nodo
  port            = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.security_group_id]

  # Los datos de checkout son temporales: no se guardan snapshots
  snapshot_retention_limit = 0

  apply_immediately = true

  tags = {
    Name = "${var.name}-redis"
  }
}
