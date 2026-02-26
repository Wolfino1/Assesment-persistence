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
# Configuración de Aurora PostgreSQL Serverless v2
# ============================================================================

aurora_engine_version           = "16.4"
aurora_serverless_min_capacity  = 0.5 # Mínimo 0.5 ACU
aurora_serverless_max_capacity  = 1.0 # Máximo 1.0 ACU (ajustar según necesidad)
aurora_backup_retention_period  = 7
aurora_backup_window            = "03:00-04:00"
aurora_maintenance_window       = "mon:04:00-mon:05:00"
aurora_deletion_protection      = true
aurora_skip_final_snapshot      = false

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
