output "address" {
  description = "Nombre DNS del nodo de Redis."
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "port" {
  description = "Puerto de Redis."
  value       = aws_elasticache_cluster.this.cache_nodes[0].port
}

output "url" {
  description = "URL de conexión para checkout (RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL)."
  value       = "redis://${aws_elasticache_cluster.this.cache_nodes[0].address}:${aws_elasticache_cluster.this.cache_nodes[0].port}"
}

output "cluster_id" {
  description = "Nombre del cluster de Redis (por ejemplo, tero-dev-redis). CloudWatch lo usa para las métricas de Redis."
  value       = aws_elasticache_cluster.this.cluster_id
}
