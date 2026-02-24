# ============================================================================
# Provider Configuration
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ============================================================================
# Data Sources - Detección Automática de Recursos (PC-IAC-020)
# ============================================================================

# Buscar VPC por tags de gobernanza
data "aws_vpc" "selected" {
  count = var.vpc_id == "" ? 1 : 0

  tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }
}

# Buscar subnets privadas de datos (Type = "Data")
data "aws_subnets" "data" {
  count = length(var.data_subnet_ids) == 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
    Type        = "Data"
  }
}

# Buscar Security Group de base de datos
data "aws_security_group" "db" {
  count = var.sg_db_id == "" ? 1 : 0

  vpc_id = local.vpc_id

  tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
    Name        = "${var.client}-${var.project}-${var.environment}-sg-db"
  }
}

# Buscar KMS Key
data "aws_kms_key" "selected" {
  count = var.kms_key_arn == "" ? 1 : 0

  key_id = "alias/${var.client}-${var.project}-${var.environment}-key"
}

# Buscar Secret de base de datos
data "aws_secretsmanager_secret" "db" {
  count = var.db_secret_arn == "" ? 1 : 0

  name = "${var.client}-${var.project}-${var.environment}-db-credentials"
}

# Buscar rol de monitoreo de RDS
data "aws_iam_role" "rds_monitoring" {
  count = var.rds_monitoring_role_arn == "" ? 1 : 0

  name = "${var.client}-${var.project}-${var.environment}-rds-monitoring-role"
}

# Obtener credenciales del secreto
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = local.db_secret_arn
}

# ============================================================================
# RDS PostgreSQL - Subnet Group
# ============================================================================

resource "aws_db_subnet_group" "postgres" {
  name       = local.rds_subnet_group_name
  subnet_ids = local.data_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = local.rds_subnet_group_name
    }
  )
}

# ============================================================================
# RDS PostgreSQL - Parameter Group
# ============================================================================

resource "aws_db_parameter_group" "postgres" {
  name   = local.rds_parameter_group_name
  family = "postgres16"

  # Configuraciones de seguridad y performance
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.rds_parameter_group_name
    }
  )
}

# ============================================================================
# RDS PostgreSQL - Instance (PC-IAC-020: Cifrado, Multi-AZ, Monitoring)
# ============================================================================

resource "aws_db_instance" "postgres" {
  identifier = local.rds_identifier

  # Motor y versión
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  # Almacenamiento
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = local.kms_key_arn

  # Credenciales desde Secrets Manager
  username = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
  db_name  = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["dbname"]

  # Red y seguridad
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [local.sg_db_id]
  publicly_accessible    = false

  # Multi-AZ
  multi_az = var.rds_multi_az

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Backups
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  maintenance_window      = var.rds_maintenance_window
  copy_tags_to_snapshot   = true

  # Enhanced Monitoring (PC-IAC-020)
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = local.rds_monitoring_role_arn

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = local.kms_key_arn
  performance_insights_retention_period = 7

  # Protección
  deletion_protection       = var.rds_deletion_protection
  skip_final_snapshot       = var.rds_skip_final_snapshot
  final_snapshot_identifier = var.rds_skip_final_snapshot ? null : "${local.rds_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = merge(
    local.common_tags,
    {
      Name = local.rds_identifier
    }
  )
}

# ============================================================================
# ElastiCache Redis - Subnet Group
# ============================================================================

resource "aws_elasticache_subnet_group" "redis" {
  name       = local.elasticache_subnet_group_name
  subnet_ids = local.data_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = local.elasticache_subnet_group_name
    }
  )
}

# ============================================================================
# ElastiCache Redis - Parameter Group
# ============================================================================

resource "aws_elasticache_parameter_group" "redis" {
  name   = local.elasticache_parameter_group_name
  family = "redis7"

  # Configuraciones de seguridad
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.elasticache_parameter_group_name
    }
  )
}

# ============================================================================
# ElastiCache Redis - Cluster (PC-IAC-020: Cifrado en tránsito y reposo)
# ============================================================================

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = local.elasticache_cluster_id
  engine               = "redis"
  engine_version       = var.elasticache_engine_version
  node_type            = var.elasticache_node_type
  num_cache_nodes      = var.elasticache_num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  port                 = var.elasticache_port

  # Red y seguridad
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [local.sg_db_id]

  # Cifrado en tránsito (PC-IAC-020)
  transit_encryption_enabled = true

  # Snapshots
  snapshot_retention_limit = var.elasticache_snapshot_retention_limit
  snapshot_window          = var.elasticache_snapshot_window
  maintenance_window       = var.elasticache_maintenance_window

  # Logs
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.elasticache_cluster_id
    }
  )
}

# ============================================================================
# CloudWatch Log Groups para Redis
# ============================================================================

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${local.elasticache_cluster_id}/slow-log"
  retention_in_days = 7
  kms_key_id        = local.kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.elasticache_cluster_id}-slow-log"
    }
  )
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${local.elasticache_cluster_id}/engine-log"
  retention_in_days = 7
  kms_key_id        = local.kms_key_arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.elasticache_cluster_id}-engine-log"
    }
  )
}

# ============================================================================
# S3 Bucket - Landing Zone para Firehose (PC-IAC-020: Cifrado, Bloqueo Público)
# ============================================================================

resource "aws_s3_bucket" "landing_zone" {
  bucket = local.s3_bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = local.s3_bucket_name
    }
  )
}

# Bloqueo de acceso público (PC-IAC-020)
resource "aws_s3_bucket_public_access_block" "landing_zone" {
  bucket = aws_s3_bucket.landing_zone.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionado
resource "aws_s3_bucket_versioning" "landing_zone" {
  bucket = aws_s3_bucket.landing_zone.id

  versioning_configuration {
    status = var.s3_enable_versioning ? "Enabled" : "Suspended"
  }
}

# Cifrado con KMS (PC-IAC-020)
resource "aws_s3_bucket_server_side_encryption_configuration" "landing_zone" {
  bucket = aws_s3_bucket.landing_zone.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# Lifecycle Policy - Retención de 90 días
resource "aws_s3_bucket_lifecycle_configuration" "landing_zone" {
  bucket = aws_s3_bucket.landing_zone.id

  rule {
    id     = "retention-policy"
    status = "Enabled"

    filter {}

    # Transición a Glacier después de X días
    transition {
      days          = var.s3_glacier_transition_days
      storage_class = "GLACIER"
    }

    # Expiración después de 90 días
    expiration {
      days = var.s3_retention_days
    }

    # Limpiar versiones antiguas
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Logging del bucket
resource "aws_s3_bucket_logging" "landing_zone" {
  bucket = aws_s3_bucket.landing_zone.id

  target_bucket = aws_s3_bucket.landing_zone.id
  target_prefix = "logs/"
}
