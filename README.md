# Data Infrastructure - Aurora PostgreSQL Serverless v2

Este módulo de Terraform implementa la capa de datos de la aplicación con Aurora PostgreSQL Serverless v2, caché en memoria y almacenamiento de objetos, siguiendo las mejores prácticas de seguridad y las reglas PC-IAC de Pragma CloudOps.

## Descripción

El módulo despliega una arquitectura de datos completa que incluye:

### Aurora PostgreSQL Serverless v2 (Cluster Multi-AZ)
- 1 Cluster Aurora PostgreSQL con 2 instancias Serverless v2
- **Writer Instance (AZ-a)**: Instancia principal para operaciones de escritura
- **Reader Instance (AZ-b)**: Réplica de lectura para balanceo de carga
- Escalabilidad automática (0.5 - 1.0 ACU configurable)
- Enhanced Monitoring habilitado (métricas cada 60 segundos)
- Performance Insights habilitado en ambas instancias
- Cifrado en reposo con KMS Customer Managed Key
- Backups automáticos con retención configurable
- Logs exportados a CloudWatch (postgresql)

### Caché en Memoria
- 1 ElastiCache Redis con capacidad mínima (cache.t4g.micro)
- Cifrado en tránsito (TLS) habilitado
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

## Arquitectura de Aurora

### Configuración Multi-AZ

```
Aurora Cluster
├── Writer Instance (AZ-a)
│   ├── Endpoint: <cluster-id>.cluster-<region>.rds.amazonaws.com
│   ├── Role: Escritura (INSERT, UPDATE, DELETE)
│   └── Serverless v2: 0.5 - 1.0 ACU
│
└── Reader Instance (AZ-b)
    ├── Endpoint: <cluster-id>.cluster-ro-<region>.rds.amazonaws.com
    ├── Role: Lectura (SELECT)
    └── Serverless v2: 0.5 - 1.0 ACU
```

### Endpoints de Conexión

Aurora proporciona dos endpoints principales:

1. **Writer Endpoint (Cluster Endpoint)**: 
   - Para operaciones de escritura y lectura
   - Siempre apunta a la instancia Writer
   - Failover automático en caso de falla

2. **Reader Endpoint**: 
   - Para operaciones de solo lectura
   - Balanceo automático entre réplicas de lectura
   - Mejora el rendimiento distribuyendo la carga

### Serverless v2 Scaling

Aurora Serverless v2 ajusta automáticamente la capacidad de cómputo:

- **Min Capacity**: 0.5 ACU (Aurora Capacity Units)
- **Max Capacity**: 1.0 ACU (configurable según necesidad)
- **Escalado**: Automático basado en la carga de trabajo
- **Costo**: Paga solo por la capacidad utilizada

## Migración desde RDS Multi-AZ

Este módulo reemplaza la configuración anterior de RDS PostgreSQL Multi-AZ con Aurora Serverless v2.

### Ventajas de Aurora

| Característica | RDS Multi-AZ | Aurora Serverless v2 |
|----------------|--------------|----------------------|
| Arquitectura | Instancia única con standby | Cluster con múltiples instancias |
| Escalabilidad | Manual (cambio de instance class) | Automática (ACU scaling) |
| Endpoints | 1 endpoint | 2 endpoints (writer/reader) |
| Almacenamiento | EBS (gp3) | Almacenamiento distribuido |
| Replicación | Síncrona a standby | Replicación a nivel de storage |
| Failover | 1-2 minutos | < 30 segundos |
| Rendimiento | PostgreSQL estándar | Hasta 3x más rápido |
| Backups | Snapshots a S3 | Backups continuos |
| Recuperación | Point-in-time (5 min) | Point-in-time (1 seg) |

### Beneficios Clave

1. **Escalabilidad automática**: Ajusta la capacidad según la carga sin intervención manual
2. **Mejor rendimiento**: Hasta 3x más rápido que PostgreSQL estándar
3. **Alta disponibilidad mejorada**: Failover más rápido (< 30 segundos)
4. **Costos optimizados**: Paga solo por la capacidad utilizada
5. **Backups continuos**: Respaldo automático a S3 sin impacto en rendimiento
6. **Recuperación rápida**: Point-in-time recovery con granularidad de 1 segundo

## Características de Seguridad (PC-IAC-020)

### Cifrado en Reposo y en Tránsito
- Aurora PostgreSQL cifrado con KMS Customer Managed Key
- ElastiCache Redis con cifrado en tránsito (TLS) y reposo
- S3 Bucket cifrado con KMS
- Performance Insights cifrado con KMS
- CloudWatch Logs cifrados con KMS

### Principio de Mínimo Privilegio
- Security Groups específicos para bases de datos
- Credenciales almacenadas en Secrets Manager
- Roles IAM con permisos mínimos necesarios

### Privacidad de Red
- Todas las instancias en subnets privadas
- Sin acceso público habilitado
- Acceso a través de VPC Endpoints

### Observabilidad
- Enhanced Monitoring en ambas instancias (60s)
- Performance Insights en ambas instancias (7 días)
- Logs de PostgreSQL exportados a CloudWatch
- Logs de Redis en CloudWatch

### Alta Disponibilidad
- Writer en AZ-a, Reader en AZ-b
- Failover automático en caso de falla
- Backups automáticos con retención de 7 días
- Replicación automática entre AZs

## Uso

### Opción 1: Detección Automática (Recomendado)

```hcl
module "data_infrastructure" {
  source = "./data-infrastructure"

  # Variables de gobernanza (requeridas)
  client      = "pragma"
  project     = "Assesment"
  environment = "dev"
  region      = "us-east-1"

  # Configuración de Aurora PostgreSQL Serverless v2
  aurora_engine_version          = "16.4"
  aurora_serverless_min_capacity = 0.5
  aurora_serverless_max_capacity = 1.0
  aurora_backup_retention_period = 7
  aurora_deletion_protection     = true

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

```hcl
module "data_infrastructure" {
  source = "./data-infrastructure"

  # Variables de gobernanza
  client      = "pragma"
  project     = "Assesment"
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
| aurora_engine_version | Versión del motor Aurora PostgreSQL | string | "16.4" | No |
| aurora_serverless_min_capacity | Capacidad mínima de ACU | number | 0.5 | No |
| aurora_serverless_max_capacity | Capacidad máxima de ACU | number | 1.0 | No |
| aurora_backup_retention_period | Días de retención de backups | number | 7 | No |
| aurora_deletion_protection | Protección contra eliminación | bool | true | No |

## Outputs

| Nombre | Descripción |
|--------|-------------|
| aurora_cluster_endpoint | Endpoint de escritura (Writer) |
| aurora_reader_endpoint | Endpoint de lectura (Reader) |
| aurora_writer_instance_endpoint | Endpoint específico de la instancia Writer |
| aurora_reader_instance_endpoint | Endpoint específico de la instancia Reader |
| aurora_cluster_id | ID del cluster Aurora |
| aurora_cluster_port | Puerto del cluster (5432) |
| aurora_database_name | Nombre de la base de datos |
| data_infrastructure_summary | Resumen completo de la infraestructura |

## Conexión a Aurora

### Usando Writer Endpoint (Escritura)

```bash
# Obtener credenciales desde Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id pragma-Assesment-dev-db-credentials \
  --query SecretString \
  --output text | jq -r

# Conectar al Writer para operaciones de escritura
psql -h <aurora_cluster_endpoint> -U <username> -d <database_name>
```

### Usando Reader Endpoint (Lectura)

```bash
# Conectar al Reader para operaciones de solo lectura
psql -h <aurora_reader_endpoint> -U <username> -d <database_name>
```

### Mejores Prácticas de Conexión

1. **Escritura**: Usa el Writer Endpoint para INSERT, UPDATE, DELETE
2. **Lectura**: Usa el Reader Endpoint para SELECT y reportes
3. **Balanceo**: El Reader Endpoint distribuye automáticamente la carga
4. **Failover**: El Writer Endpoint maneja automáticamente el failover

## Requisitos

- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- Credenciales de AWS configuradas
- Módulo de networking desplegado (con subnets Type = "Data" en 2 AZs)
- Módulo de seguridad desplegado (Security Groups, KMS, Secrets Manager)

### Requisitos para Detección Automática

**Subnets de Datos (IMPORTANTE):**
- Deben existir al menos 2 subnets con tag `Type = "Data"`
- Primera subnet (AZ-a): Para la instancia Writer
- Segunda subnet (AZ-b): Para la instancia Reader
- Tags requeridos: `Client`, `Project`, `Environment`, `Type = "Data"`

## Cumplimiento de Reglas PC-IAC

| Regla | Descripción | Implementación |
|-------|-------------|----------------|
| PC-IAC-002 | Variables de Gobernanza | Variables client, project, environment con validaciones |
| PC-IAC-003 | Nomenclatura Estándar | Prefijo de gobernanza en todos los recursos |
| PC-IAC-004 | Etiquetas Obligatorias | Tags comunes aplicados mediante merge |
| PC-IAC-020 | Seguridad (Hardenizado) | Cifrado, mínimo privilegio, Enhanced Monitoring, bloqueo público |

## Monitoreo y Observabilidad

### CloudWatch Logs

- Aurora PostgreSQL: `/aws/rds/cluster/{cluster_id}/postgresql`
- Redis Slow Log: `/aws/elasticache/{cluster_id}/slow-log`
- Redis Engine Log: `/aws/elasticache/{cluster_id}/engine-log`

### CloudWatch Metrics

- Aurora: CPU, memoria, conexiones, latencia, throughput
- Métricas por instancia (Writer y Reader)
- ElastiCache: CPU, memoria, conexiones, comandos

### Performance Insights

- Habilitado en ambas instancias (Writer y Reader)
- Retención de 7 días
- Análisis detallado de queries
- Identificación de cuellos de botella

## Costos Estimados (us-east-1)

### Aurora Serverless v2
- ACU-hora: $0.12 por ACU
- Configuración mínima (0.5 ACU x 2 instancias): ~$18/mes
- Almacenamiento: $0.10 por GB-mes
- I/O: $0.20 por millón de requests
- Backups: Gratis hasta 100% del tamaño del cluster

### Comparación con RDS Multi-AZ
- RDS db.t4g.micro Multi-AZ: ~$24/mes (fijo)
- Aurora Serverless v2 (0.5-1.0 ACU): ~$18-36/mes (variable según uso)

*Nota: Aurora puede ser más económico en cargas variables y más costoso en cargas constantes.*

## Despliegue

```bash
# Inicializar Terraform
terraform init

# Planificar cambios
terraform plan -out=tfplan

# Aplicar cambios
terraform apply tfplan

# Ver outputs
terraform output
```

## Autor

Pragma CloudOps Team

## Licencia

Proprietary - Pragma
