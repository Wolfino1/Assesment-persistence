# ============================================================================
# Variables de Gobernanza
# ============================================================================

client      = "pragma"
project     = "Assesment"
environment = "dev"
region      = "us-east-1"

# ============================================================================
# Variables de Red (Opcional - Se detectan automáticamente por tags)
# ============================================================================

# vpc_id           = ""  # Se detecta automáticamente
# data_subnet_ids  = []  # Se detectan automáticamente (Type = "Data")

# ============================================================================
# Variables de Seguridad (Opcional - Se detectan automáticamente por tags)
# ============================================================================

# sg_db_id                = ""  # Se detecta automáticamente
# kms_key_arn             = ""  # Se detecta automáticamente
# db_secret_arn           = ""  # Se detecta automáticamente
# rds_monitoring_role_arn = ""  # Se detecta automáticamente

# ============================================================================
# Configuración de RDS PostgreSQL
# ============================================================================

rds_instance_class          = "db.t4g.micro" # Capacidad mínima
rds_allocated_storage       = 20
rds_max_allocated_storage   = 100
rds_engine_version          = "16.3"
rds_multi_az                = true
rds_backup_retention_period = 7
rds_backup_window           = "03:00-04:00"
rds_maintenance_window      = "mon:04:00-mon:05:00"
rds_deletion_protection     = true
rds_skip_final_snapshot     = false

# ============================================================================
# Configuración de ElastiCache Redis
# ============================================================================

elasticache_node_type                = "cache.t4g.micro" # Capacidad mínima
elasticache_num_cache_nodes          = 1
elasticache_engine_version           = "7.1"
elasticache_port                     = 6379
elasticache_snapshot_retention_limit = 5
elasticache_snapshot_window          = "05:00-06:00"
elasticache_maintenance_window       = "mon:06:00-mon:07:00"

# ============================================================================
# Configuración de S3 Bucket (Landing Zone)
# ============================================================================

s3_retention_days          = 90
s3_enable_versioning       = true
s3_glacier_transition_days = 30

# ============================================================================
# Tags Adicionales
# ============================================================================

additional_tags = {
  Owner      = "santiago.guerrero"
  CostCenter = "0000"
  Purpose    = "Data Infrastructure"
}
