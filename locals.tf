# ============================================================================
# Locals - Nomenclatura y Tags (PC-IAC-003, PC-IAC-004)
# ============================================================================

locals {
  # Prefijo de gobernanza (PC-IAC-003) - convertido a minúsculas
  governance_prefix = lower("${var.client}-${var.project}-${var.environment}")

  # Tags comunes obligatorios (PC-IAC-004)
  common_tags = merge(
    {
      Client      = var.client
      Project     = var.project
      Environment = var.environment
      Region      = var.region
      ManagedBy   = "Terraform"
      Module      = "data-infrastructure"
    },
    var.additional_tags
  )

  # Detección automática de recursos de red (si no se proporcionan)
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.selected[0].id

  # Filtrar subnets de datos (Type = "Data")
  data_subnet_ids = length(var.data_subnet_ids) > 0 ? var.data_subnet_ids : data.aws_subnets.data[0].ids

  # Detección automática de recursos de seguridad
  sg_db_id                = var.sg_db_id != "" ? var.sg_db_id : data.aws_security_group.db[0].id
  kms_key_arn             = var.kms_key_arn != "" ? var.kms_key_arn : data.aws_kms_key.selected[0].arn
  db_secret_arn           = var.db_secret_arn != "" ? var.db_secret_arn : data.aws_secretsmanager_secret.db[0].arn
  rds_monitoring_role_arn = var.rds_monitoring_role_arn != "" ? var.rds_monitoring_role_arn : data.aws_iam_role.rds_monitoring[0].arn

  # Nombres de recursos
  aurora_cluster_identifier           = "${local.governance_prefix}-aurora"
  aurora_subnet_group_name            = "${local.governance_prefix}-aurora-subnet-group"
  aurora_cluster_parameter_group_name = "${local.governance_prefix}-aurora-cluster-params"
  aurora_db_parameter_group_name      = "${local.governance_prefix}-aurora-db-params"

  elasticache_cluster_id           = "${local.governance_prefix}-redis"
  elasticache_subnet_group_name    = "${local.governance_prefix}-redis-subnet-group"
  elasticache_parameter_group_name = "${local.governance_prefix}-redis-params"

  s3_bucket_name = "${local.governance_prefix}-landing-zone"
}
