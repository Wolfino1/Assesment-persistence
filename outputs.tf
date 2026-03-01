# ============================================================================
# Outputs - Aurora PostgreSQL
# ============================================================================

output "aurora_cluster_id" {
  description = "ID del cluster Aurora PostgreSQL"
  value       = aws_rds_cluster.aurora.id
}

output "aurora_cluster_arn" {
  description = "ARN del cluster Aurora PostgreSQL"
  value       = aws_rds_cluster.aurora.arn
}

output "aurora_cluster_endpoint" {
  description = "Endpoint de escritura del cluster Aurora (Writer)"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Endpoint de lectura del cluster Aurora (Reader)"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "aurora_cluster_port" {
  description = "Puerto del cluster Aurora PostgreSQL"
  value       = aws_rds_cluster.aurora.port
}

output "aurora_database_name" {
  description = "Nombre de la base de datos"
  value       = aws_rds_cluster.aurora.database_name
  sensitive   = true
}

output "aurora_cluster_resource_id" {
  description = "Resource ID del cluster Aurora (para IAM authentication)"
  value       = aws_rds_cluster.aurora.cluster_resource_id
}

output "aurora_writer_instance_id" {
  description = "ID de la instancia writer de Aurora"
  value       = aws_rds_cluster_instance.aurora_writer.id
}

output "aurora_writer_endpoint" {
  description = "Endpoint de la instancia writer de Aurora"
  value       = aws_rds_cluster_instance.aurora_writer.endpoint
}

output "aurora_reader_instance_id" {
  description = "ID de la instancia reader de Aurora"
  value       = aws_rds_cluster_instance.aurora_reader.id
}

output "aurora_reader_instance_endpoint" {
  description = "Endpoint de la instancia reader de Aurora"
  value       = aws_rds_cluster_instance.aurora_reader.endpoint
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
    aurora_postgresql = {
      cluster_identifier = aws_rds_cluster.aurora.cluster_identifier
      writer_endpoint    = aws_rds_cluster.aurora.endpoint
      reader_endpoint    = aws_rds_cluster.aurora.reader_endpoint
      engine_version     = aws_rds_cluster.aurora.engine_version
      engine_mode        = aws_rds_cluster.aurora.engine_mode
      serverless_config = {
        min_capacity = var.aurora_serverless_min_capacity
        max_capacity = var.aurora_serverless_max_capacity
      }
      instances = {
        writer = {
          id                = aws_rds_cluster_instance.aurora_writer.id
          endpoint          = aws_rds_cluster_instance.aurora_writer.endpoint
          availability_zone = aws_rds_cluster_instance.aurora_writer.availability_zone
          role              = "Writer"
        }
        reader = {
          id                = aws_rds_cluster_instance.aurora_reader.id
          endpoint          = aws_rds_cluster_instance.aurora_reader.endpoint
          availability_zone = aws_rds_cluster_instance.aurora_reader.availability_zone
          role              = "Reader"
        }
      }
      encrypted  = aws_rds_cluster.aurora.storage_encrypted
      monitoring = "Enhanced Monitoring habilitado (60s)"
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
