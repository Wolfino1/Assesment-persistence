# ============================================================================
# Variables de Gobernanza (PC-IAC-002)
# ============================================================================

variable "client" {
  description = "Nombre del cliente (máx 10 caracteres)"
  type        = string
  validation {
    condition     = length(var.client) <= 10
    error_message = "El nombre del cliente no puede exceder 10 caracteres."
  }
}

variable "project" {
  description = "Nombre del proyecto (máx 15 caracteres)"
  type        = string
  validation {
    condition     = length(var.project) <= 15
    error_message = "El nombre del proyecto no puede exceder 15 caracteres."
  }
}

variable "environment" {
  description = "Ambiente de despliegue (dev, qa, pdn)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El ambiente debe ser dev, qa o pdn."
  }
}

variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

# ============================================================================
# Variables de Red (desde módulo de networking)
# ============================================================================

variable "vpc_id" {
  description = "ID de la VPC (desde módulo de networking)"
  type        = string
  default     = ""
}

variable "data_subnet_ids" {
  description = "IDs de las subnets privadas para datos (desde módulo de networking)"
  type        = list(string)
  default     = []
}

# ============================================================================
# Variables de Seguridad (desde módulo de seguridad)
# ============================================================================

variable "sg_db_id" {
  description = "ID del Security Group de base de datos (desde módulo de seguridad)"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS (desde módulo de seguridad)"
  type        = string
  default     = ""
}

variable "db_secret_arn" {
  description = "ARN del secreto de credenciales de base de datos (desde módulo de seguridad)"
  type        = string
  default     = ""
}

variable "rds_monitoring_role_arn" {
  description = "ARN del rol de monitoreo de RDS (desde módulo de seguridad)"
  type        = string
  default     = ""
}

# ============================================================================
# Variables de RDS PostgreSQL
# ============================================================================

variable "rds_instance_class" {
  description = "Clase de instancia para RDS PostgreSQL"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "Almacenamiento asignado en GB para RDS"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Almacenamiento máximo para autoscaling en GB"
  type        = number
  default     = 100
}

variable "rds_engine_version" {
  description = "Versión del motor PostgreSQL"
  type        = string
  default     = "16.3"
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ para RDS"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Días de retención de backups"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Ventana de backup (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Ventana de mantenimiento (UTC)"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "rds_deletion_protection" {
  description = "Habilitar protección contra eliminación"
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot" {
  description = "Omitir snapshot final al eliminar"
  type        = bool
  default     = false
}

# ============================================================================
# Variables de ElastiCache Redis
# ============================================================================

variable "elasticache_node_type" {
  description = "Tipo de nodo para ElastiCache Redis"
  type        = string
  default     = "cache.t4g.micro"
}

variable "elasticache_num_cache_nodes" {
  description = "Número de nodos de caché"
  type        = number
  default     = 1
}

variable "elasticache_engine_version" {
  description = "Versión del motor Redis"
  type        = string
  default     = "7.1"
}

variable "elasticache_port" {
  description = "Puerto de Redis"
  type        = number
  default     = 6379
}

variable "elasticache_snapshot_retention_limit" {
  description = "Días de retención de snapshots"
  type        = number
  default     = 5
}

variable "elasticache_snapshot_window" {
  description = "Ventana de snapshot (UTC)"
  type        = string
  default     = "05:00-06:00"
}

variable "elasticache_maintenance_window" {
  description = "Ventana de mantenimiento (UTC)"
  type        = string
  default     = "mon:06:00-mon:07:00"
}

# ============================================================================
# Variables de S3 Bucket (Landing Zone)
# ============================================================================

variable "s3_retention_days" {
  description = "Días de retención para objetos en S3"
  type        = number
  default     = 90
}

variable "s3_enable_versioning" {
  description = "Habilitar versionado en S3"
  type        = bool
  default     = true
}

variable "s3_glacier_transition_days" {
  description = "Días antes de transición a Glacier"
  type        = number
  default     = 30
}

# ============================================================================
# Tags Adicionales
# ============================================================================

variable "additional_tags" {
  description = "Tags adicionales para aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}
