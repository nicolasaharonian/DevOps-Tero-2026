output "alb_sg_id" {
  description = "ID del security group del ALB publico (entrada HTTP desde internet)."
  value       = aws_security_group.alb.id
}

output "internal_alb_sg_id" {
  description = "ID del security group del ALB interno (solo acepta trafico desde ECS)."
  value       = aws_security_group.internal_alb.id
}

output "ecs_sg_id" {
  description = "ID del security group de las tareas ECS (microservicios)."
  value       = aws_security_group.ecs.id
}

output "db_sg_id" {
  description = "ID del security group de RDS PostgreSQL (solo acepta trafico desde ECS)."
  value       = aws_security_group.db.id
}

output "redis_sg_id" {
  description = "ID del security group de ElastiCache Redis (solo acepta trafico desde ECS)."
  value       = aws_security_group.redis.id
}