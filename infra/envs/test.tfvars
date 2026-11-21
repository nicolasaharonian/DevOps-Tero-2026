environment = "test"
vpc_cidr    = "10.30.0.0/16"
az_count    = 2
# Base de datos y Redis: igual que dev
db_instance_class        = "db.t3.micro"
db_multi_az              = false
db_backup_retention_days = 1
db_deletion_protection   = false
db_skip_final_snapshot   = true
redis_node_type          = "cache.t3.micro"
