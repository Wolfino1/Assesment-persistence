# Data Infrastructure - Terraform Module

Este módulo de Terraform implementa la capa de datos de la aplicación, incluyendo base de datos relacional, caché en memoria y almacenamiento de objetos, siguiendo las mejores prácticas de seguridad y las reglas PC-IAC de Pragma CloudOps.

## Descripción

El módulo despliega una arquitectura de datos completa que incluye:

### Base de Datos Relacional
- 1 RDS PostgreSQL con capacidad mínima (db.t4g.micro)
- Multi-AZ configurable por variable
- Enhanced Monitoring habilitado (métricas cada 60 segundos)
- Performance Insights habilitado
- Cifrado en reposo con KMS Customer Managed Key
- Backups automáticos con retención configurable
- Logs exportados a CloudWatch (postgresql, upgrade)

### Caché en Memoria
- 1 ElastiCache Redis con capacidad mínima (cache.t4g.micro)
- Cifrado en tránsito (TLS) habilitado
- Cifrado en reposo con KMS habilitado
- Snapshots automáticos con retención configurable
- Logs de slow-log y engine-log en CloudWatch

### Almacenamiento de Objetos (Landing Zone)
- 1 S3 Bucket para Kinesis Firehose
- Bloqueo total de acceso público
- Cifrado con KMS Customer Managed Key
- Versionado habilitado
- Política de retención de 90 días
- Transición automática a Glacier después de 30 días
- Logging habilitado

## Arquitectura de Datos

### Flujo de Datos

```
ECS Fargate (Aplicación)
    ↓ (lectura/escritura)
RDS PostgreSQL (Datos relacionales)
    ↓ (caché)
ElastiCache Redis (Datos en memoria)
    ↓ (eventos)
Kinesis Data Streams
    ↓ (procesamiento)
Kinesis Firehose
    ↓ (almacenamiento)
S3 Bucket (Landing Zone)
```

### Integración con Módulos Existentes

Este módulo se integra con:

1. **Módulo de Networking**: Utiliza las subnets privadas de datos (Type = "Data")
2. **Módulo de Seguridad**: Utiliza Security Groups, KMS Key, Secrets Manager y roles IAM

## Características de Seguridad (PC-IAC-020)

### Cifrado en Reposo y en Tránsito
- RDS PostgreSQL cifrado con KMS Customer Managed Key
- ElastiCache Redis con cifrado en tránsito (TLS) y reposo (KMS)
- S3 Bucket cifrado con KMS
- Performance Insights cifrado con KMS
- CloudWatch Logs cifrados con KMS

### Principio de Mínimo Privilegio
- Security Groups específicos para bases de datos (desde módulo de seguridad)
- Credenciales almacenadas en Secrets Manager (no hardcoded)
- Roles IAM con permisos mínimos necesarios

### Privacidad de Red
- Todos los recursos en subnets privadas (sin acceso directo a Internet)
- Acceso a través de VPC Endpoints configurados en módulo de networking
- Bloqueo total de acceso público en S3

### Observabilidad
- Enhanced Monitoring en RDS (métricas cada 60 segundos)
- Performance Insights en RDS (retención de 7 días)
- Logs de PostgreSQL exportados a CloudWatch
- Logs de Redis (slow-log y engine-log) en CloudWatch
- Logging de acceso a S3

### Alta Disponibilidad
- Multi-AZ configurable para RDS PostgreSQL
- Backups automáticos con retención de 7 días
- Snapshots de Redis con retención de 5 días
- Versionado habilitado en S3

## Uso

### Opción 1: Detección Automática (Recomendado)

El módulo puede detectar automáticamente los recursos de red y seguridad usando los tags de gobernanza:

```hcl
module "data_infrastructure" {
  source = "./data-infrastructure"

  # Variables de gobernanza (requeridas)
  client      = "pragma"
  project     = "myproject"
  environment = "dev"
  region      = "us-east-1"

  # Variables de red y seguridad: NO es necesario especificarlas
  # El módulo las buscará automáticamente por tags

  # Configuración de RDS PostgreSQL
  rds_instance_class          = "db.t4g.micro"
  rds_multi_az                = false  # true para producción
  rds_backup_retention_period = 7

  # Configuración de ElastiCache Redis
  elasticache_node_type       = "cache.t4g.micro"
  elasticache_num_cache_nodes = 1

  # Configuración de S3
  s3_retention_days = 90

  # Tags adicionales
  additional_tags = {
    Owner      = "CloudOps Team"
    CostCenter = "Engineering"
  }
}
```

### Opción 2: Especificación Manual

Si prefieres especificar manualmente los valores:

```hcl
module "data_infrastructure" {
  source = "./data-infrastructure"

  # Variables de gobernanza
  client      = "pragma"
  project     = "myproject"
  environment = "dev"
  region      = "us-east-1"

  # Variables de red (especificadas manualmente)
  vpc_id          = module.networking.vpc_id
  data_subnet_ids = module.networking.data_subnet_ids

  # Variables de seguridad (especificadas manualmente)
  sg_db_id                = module.security.sg_db_id
  kms_key_arn             = module.security.kms_key_arn
  db_secret_arn           = module.security.db_secret_arn
  rds_monitoring_role_arn = module.security.rds_monitoring_role_arn

  # Resto de configuración...
}
```

## Inputs

| Nombre | Descripción | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| client | Nombre del cliente (máx 10 caracteres) | string | - | Sí |
| project | Nombre del proyecto (máx 15 caracteres) | string | - | Sí |
| environment | Ambiente de despliegue (dev, qa, pdn) | string | - | Sí |
| region | Región de AWS | string | "us-east-1" | No |
| vpc_id | ID de la VPC. Si no se proporciona, se busca automáticamente | string | "" | No |
| data_subnet_ids | IDs de las subnets de datos. Si no se proporciona, se buscan automáticamente | list(string) | [] | No |
| sg_db_id | ID del Security Group de base de datos. Si no se proporciona, se busca automáticamente | string | "" | No |
| kms_key_arn | ARN de la llave KMS. Si no se proporciona, se busca automáticamente | string | "" | No |
| db_secret_arn | ARN del secreto de credenciales. Si no se proporciona, se busca automáticamente | string | "" | No |
| rds_monitoring_role_arn | ARN del rol de monitoreo de RDS. Si no se proporciona, se busca automáticamente | string | "" | No |
| rds_instance_class | Clase de instancia para RDS | string | "db.t4g.micro" | No |
| rds_allocated_storage | Almacenamiento asignado en GB | number | 20 | No |
| rds_max_allocated_storage | Almacenamiento máximo para autoscaling | number | 100 | No |
| rds_engine_version | Versión del motor PostgreSQL | string | "16.3" | No |
| rds_multi_az | Habilitar Multi-AZ | bool | false | No |
| rds_backup_retention_period | Días de retención de backups | number | 7 | No |
| rds_deletion_protection | Protección contra eliminación | bool | true | No |
| elasticache_node_type | Tipo de nodo para Redis | string | "cache.t4g.micro" | No |
| elasticache_num_cache_nodes | Número de nodos de caché | number | 1 | No |
| elasticache_engine_version | Versión del motor Redis | string | "7.1" | No |
| s3_retention_days | Días de retención en S3 | number | 90 | No |
| s3_enable_versioning | Habilitar versionado en S3 | bool | true | No |
| s3_glacier_transition_days | Días antes de transición a Glacier | number | 30 | No |
| additional_tags | Tags adicionales | map(string) | {} | No |

## Outputs

| Nombre | Descripción |
|--------|-------------|
| rds_instance_id | ID de la instancia RDS PostgreSQL |
| rds_endpoint | Endpoint de conexión de RDS |
| rds_address | Dirección DNS de RDS |
| rds_port | Puerto de RDS |
| rds_database_name | Nombre de la base de datos |
| elasticache_cluster_id | ID del cluster ElastiCache Redis |
| elasticache_endpoint | Endpoint de conexión de Redis |
| elasticache_port | Puerto de Redis |
| s3_bucket_id | ID del bucket S3 Landing Zone |
| s3_bucket_arn | ARN del bucket S3 |
| vpc_id | ID de la VPC utilizada |
| data_subnet_ids | IDs de las subnets de datos utilizadas |
| security_group_id | ID del Security Group utilizado |
| kms_key_arn | ARN de la llave KMS utilizada |
| data_infrastructure_summary | Resumen completo de la infraestructura creada |

## Requisitos

- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- Credenciales de AWS configuradas
- Módulo de networking desplegado previamente (con subnets Type = "Data")
- Módulo de seguridad desplegado previamente (con Security Groups, KMS, Secrets Manager)

### Requisitos para Detección Automática

Para que el módulo pueda detectar automáticamente los recursos, deben existir con los siguientes tags:

**VPC:**
- `Client` = valor de var.client
- `Project` = valor de var.project
- `Environment` = valor de var.environment

**Subnets de Datos:**
- `Client` = valor de var.client
- `Project` = valor de var.project
- `Environment` = valor de var.environment
- `Type` = "Data"

**Security Group de Base de Datos:**
- `Client` = valor de var.client
- `Project` = valor de var.project
- `Environment` = valor de var.environment
- `Name` = "{client}-{project}-{environment}-sg-db"

**KMS Key:**
- Alias: `alias/{client}-{project}-{environment}-key`

**Secret de Base de Datos:**
- Name: `{client}-{project}-{environment}-db-credentials`

**Rol de Monitoreo de RDS:**
- Name: `{client}-{project}-{environment}-rds-monitoring-role`

## Cumplimiento de Reglas PC-IAC

| Regla | Descripción | Implementación |
|-------|-------------|----------------|
| PC-IAC-002 | Variables de Gobernanza | Variables client, project, environment con validaciones |
| PC-IAC-003 | Nomenclatura Estándar | Prefijo de gobernanza en todos los recursos |
| PC-IAC-004 | Etiquetas Obligatorias | Tags comunes aplicados mediante merge |
| PC-IAC-010 | For_Each y Control | Uso de for_each para recursos múltiples |
| PC-IAC-020 | Seguridad (Hardenizado) | Cifrado, mínimo privilegio, Enhanced Monitoring, bloqueo público |

## Decisiones de Diseño

### Capacidad Mínima
Se utilizan las instancias más pequeñas disponibles en AWS:
- RDS: `db.t4g.micro` (2 vCPU, 1 GB RAM)
- ElastiCache: `cache.t4g.micro` (2 vCPU, 0.5 GB RAM)

Estas instancias son ideales para desarrollo y pruebas. Para producción, se recomienda escalar según las necesidades.

### Multi-AZ Configurable
Multi-AZ está deshabilitado por defecto para reducir costos en desarrollo. Para producción, se recomienda habilitarlo mediante la variable `rds_multi_az = true`.

### Enhanced Monitoring
Se habilita Enhanced Monitoring con intervalo de 60 segundos para tener visibilidad detallada del rendimiento de RDS, cumpliendo con PC-IAC-020.

### Cifrado Obligatorio
Todos los recursos de almacenamiento utilizan cifrado con KMS Customer Managed Key:
- RDS PostgreSQL (datos y Performance Insights)
- ElastiCache Redis (en tránsito y reposo)
- S3 Bucket
- CloudWatch Logs

### Retención de Datos
- Backups de RDS: 7 días (configurable)
- Snapshots de Redis: 5 días (configurable)
- Objetos en S3: 90 días con transición a Glacier a los 30 días
- Performance Insights: 7 días
- CloudWatch Logs: 7 días

### Detección Automática de Recursos
El módulo utiliza data sources para buscar automáticamente los recursos de red y seguridad basándose en los tags de gobernanza, eliminando la necesidad de hardcodear IDs y facilitando la integración entre módulos.

## Conexión a los Recursos

### RDS PostgreSQL

```bash
# Obtener credenciales desde Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id pragma-myproject-dev-db-credentials \
  --query SecretString \
  --output text | jq -r

# Conectar usando psql
psql -h <rds_endpoint> -U <username> -d <database_name>
```

### ElastiCache Redis

```bash
# Conectar usando redis-cli (requiere TLS)
redis-cli -h <elasticache_endpoint> -p 6379 --tls
```

### S3 Bucket

```bash
# Listar objetos
aws s3 ls s3://pragma-myproject-dev-landing-zone/

# Copiar archivo
aws s3 cp file.txt s3://pragma-myproject-dev-landing-zone/
```

## Monitoreo y Observabilidad

### CloudWatch Logs

- RDS PostgreSQL: `/aws/rds/instance/{identifier}/postgresql`
- Redis Slow Log: `/aws/elasticache/{cluster_id}/slow-log`
- Redis Engine Log: `/aws/elasticache/{cluster_id}/engine-log`

### CloudWatch Metrics

- RDS: CPU, memoria, IOPS, conexiones, latencia
- ElastiCache: CPU, memoria, conexiones, comandos, evictions
- S3: Requests, bytes, errors

### Performance Insights

Accede a Performance Insights desde la consola de RDS para análisis detallado de queries y rendimiento.

## Costos Estimados (us-east-1)

### Desarrollo (configuración mínima)
- RDS db.t4g.micro: ~$12/mes
- ElastiCache cache.t4g.micro: ~$11/mes
- S3 (100 GB): ~$2.30/mes
- Total aproximado: ~$25/mes

### Producción (Multi-AZ, mayor capacidad)
- RDS db.t4g.small Multi-AZ: ~$50/mes
- ElastiCache cache.t4g.small: ~$22/mes
- S3 (1 TB): ~$23/mes
- Total aproximado: ~$95/mes

*Nota: Los costos no incluyen transferencia de datos, backups adicionales ni otros servicios.*

## Seguridad Adicional

### Rotación de Secretos
Configura rotación automática del secreto de base de datos después del despliegue:

```bash
aws secretsmanager rotate-secret \
  --secret-id pragma-myproject-dev-db-credentials \
  --rotation-lambda-arn <lambda_arn> \
  --rotation-rules AutomaticallyAfterDays=30
```

### Auditoría de Acceso
Revisa los logs de CloudWatch regularmente para detectar patrones anómalos de acceso.

### Backups y Recuperación
Prueba regularmente la restauración desde backups para garantizar la continuidad del negocio.

## Autor

Pragma CloudOps Team

## Licencia

Proprietary - Pragma
