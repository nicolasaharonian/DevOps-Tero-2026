output "vpc_id" {
  description = "ID de la VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas (ALB y tareas de ECS)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas (base de datos y Redis)."
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Zonas de disponibilidad usadas."
  value       = local.azs
}
 