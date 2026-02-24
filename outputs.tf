# ============================================================================
# Outputs - RDS PostgreSQL
# ============================================================================

output "rds_instance_id" {
  description = "ID de la instancia RDS PostgreSQL"
  value       = aws_db_instance.postgres.id
}

output "rds_instance_arn" {
  description = "ARN de la instancia RDS PostgreSQL"
  value       = aws_db_instance.postgres.arn
}

output "rds_endpoint" {
  description = "Endpoint de conexión de RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "Dirección DNS de RDS PostgreSQL"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Puerto de RDS PostgreSQL"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.postgres.db_name
}

output "rds_resource_id" {
  description = "Resource ID de RDS (para IAM authentication)"
  value       = aws_db_instance.postgres.resource_id
}

# ============================================================================
# Outputs - ElastiCache Redis
# ============================================================================

output "elasticache_cluster_id" {
  description = "ID del cluster ElastiCache Redis"
  value       = aws_elasticache_cluster.redis.id
}

output "elasticache_cluster_arn" {
  description = "ARN del cluster ElastiCache Redis"
  value       = aws_elasticache_cluster.redis.arn
}

output "elasticache_endpoint" {
  description = "Endpoint de conexión de Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "elasticache_port" {
  description = "Puerto de Redis"
  value       = aws_elasticache_cluster.redis.port
}

output "elasticache_configuration_endpoint" {
  description = "Configuration endpoint de Redis"
  value       = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
}

# ============================================================================
# Outputs - S3 Bucket
# ============================================================================

output "s3_bucket_id" {
  description = "ID del bucket S3 Landing Zone"
  value       = aws_s3_bucket.landing_zone.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3 Landing Zone"
  value       = aws_s3_bucket.landing_zone.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name del bucket S3"
  value       = aws_s3_bucket.landing_zone.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name del bucket S3"
  value       = aws_s3_bucket.landing_zone.bucket_regional_domain_name
}

# ============================================================================
# Outputs - Recursos Detectados
# ============================================================================

output "vpc_id" {
  description = "ID de la VPC utilizada"
  value       = local.vpc_id
}

output "data_subnet_ids" {
  description = "IDs de las subnets de datos utilizadas"
  value       = local.data_subnet_ids
}

output "security_group_id" {
  description = "ID del Security Group de base de datos utilizado"
  value       = local.sg_db_id
}

output "kms_key_arn" {
  description = "ARN de la llave KMS utilizada"
  value       = local.kms_key_arn
}

# ============================================================================
# Output - Resumen de Infraestructura
# ============================================================================

output "data_infrastructure_summary" {
  description = "Resumen de la infraestructura de datos creada"
  value = {
    rds_postgres = {
      identifier     = aws_db_instance.postgres.identifier
      endpoint       = aws_db_instance.postgres.endpoint
      engine_version = aws_db_instance.postgres.engine_version
      instance_class = aws_db_instance.postgres.instance_class
      multi_az       = aws_db_instance.postgres.multi_az
      encrypted      = aws_db_instance.postgres.storage_encrypted
      monitoring     = "Enhanced Monitoring habilitado (60s)"
    }
    elasticache_redis = {
      cluster_id     = aws_elasticache_cluster.redis.cluster_id
      endpoint       = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
      engine_version = aws_elasticache_cluster.redis.engine_version
      node_type      = aws_elasticache_cluster.redis.node_type
      num_nodes      = aws_elasticache_cluster.redis.num_cache_nodes
      encrypted      = "Cifrado en tránsito habilitado (TLS)"
    }
    s3_landing_zone = {
      bucket_name    = aws_s3_bucket.landing_zone.id
      versioning     = var.s3_enable_versioning ? "Enabled" : "Suspended"
      encryption     = "KMS"
      retention_days = var.s3_retention_days
      public_access  = "Bloqueado"
    }
  }
}
