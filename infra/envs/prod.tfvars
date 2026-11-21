environment = "prod"
vpc_cidr    = "10.30.0.0/16"
az_count    = 2
# Base de datos: réplica en otra zona y backups de una semana.
# deletion_protection queda en false para poder limpiar el Learner Lab;
# en una cuenta real de producción iría en true.
db_instance_class        = "db.t3.micro"
db_multi_az              = true
db_backup_retention_days = 7
db_deletion_protection   = false
db_skip_final_snapshot   = true
redis_node_type          = "cache.t3.micro"
