# Networking Infrastructure - Terraform Module

Este módulo de Terraform crea una infraestructura de red completa en AWS siguiendo las mejores prácticas de seguridad y las reglas PC-IAC de Pragma CloudOps.

## Descripción

El módulo despliega una arquitectura de red robusta y segura que incluye:

- 1 VPC con DNS habilitado
- 2 subnets públicas (distribuidas en diferentes AZs)
- 4 subnets privadas (2 para app, 2 para data - distribuidas en diferentes AZs)
- 1 Internet Gateway para conectividad pública
- 2 NAT Gateways (uno por AZ) para alta disponibilidad
- 2 Elastic IPs (una por cada NAT Gateway)
- 2 tablas de rutas privadas (una por AZ)
- 1 tabla de rutas pública
- 1 S3 Gateway Endpoint para acceso privado a S3
- 5 VPC Endpoints de tipo Interface optimizados para ECS Fargate con Kinesis:
  - `ecr.api` - API de ECR (obligatorio para Fargate)
  - `ecr.dkr` - Docker registry de ECR (obligatorio para Fargate)
  - `secretsmanager` - Para secrets en task definitions
  - `logs` - Para logs básicos en CloudWatch (sin Container Insights)
  - `kinesis-streams` - Para enviar eventos desde ECS a Kinesis Data Streams
- Security Group para VPC Endpoints con principio de mínimo privilegio

### ¿Por qué 2 VPC Endpoints para ECR?

AWS ECR requiere **dos endpoints separados** para funcionar correctamente:

1. **ecr.api** - Gestiona operaciones de la API de ECR:
   - Autenticación (`GetAuthorizationToken`)
   - Listar imágenes (`DescribeImages`)
   - Obtener manifiestos
   
2. **ecr.dkr** - Maneja el tráfico de Docker:
   - Pull de imágenes Docker
   - Push de imágenes Docker
   - Transferencia de layers

**Ambos son obligatorios** para que ECS Fargate pueda descargar imágenes desde ECR en subnets privadas sin acceso a Internet.

### S3 Gateway Endpoint

**¿Para qué sirve?**

El S3 Gateway Endpoint permite acceso privado a **TODOS los buckets de S3** desde tu VPC sin pasar por Internet o NAT Gateway.

**Características importantes:**

1. **Único para toda la VPC** - Un solo endpoint sirve para todos los buckets S3
2. **Completamente gratuito** - No tiene costo por hora ni por transferencia de datos
3. **Asociado a tablas de rutas** - Se configura en las tablas de rutas privadas
4. **Transparente** - Funciona automáticamente sin configuración adicional en las aplicaciones

**Casos de uso cubiertos:**

- ✅ Kinesis Firehose escribiendo datos a S3
- ✅ ECS Fargate leyendo/escribiendo archivos en S3
- ✅ Lambda functions accediendo a S3
- ✅ Cualquier servicio en subnets privadas → S3

**Nota importante:** Las imágenes de Docker en ECR **NO usan S3 Gateway Endpoint**. ECR tiene sus propios endpoints (`ecr.api` y `ecr.dkr`) que ya están configurados.

### Logs y Métricas

**Logs básicos (incluidos):**
- El endpoint `logs` permite enviar logs a CloudWatch Logs desde subnets privadas
- No requiere Container Insights
- Logs disponibles en CloudWatch Logs para troubleshooting
- Costo: Solo almacenamiento (~$0.50/GB)

**Métricas básicas (automáticas):**
- CPU, memoria, red a nivel de task/service
- Se envían automáticamente sin necesidad de endpoints adicionales
- Visibles en la consola de ECS y CloudWatch Metrics
- Completamente gratuitas

**Container Insights (NO incluido):**
- No se incluye `ecs-telemetry` porque no se usa Container Insights
- Si necesitas métricas detalladas, considera usar Datadog

### Arquitectura con Kinesis para Amazon Personalize

**Flujo de datos:**
```
ECS Fargate (subnets privadas)
    ↓ (usa endpoint kinesis-streams)
Kinesis Data Streams (servicio gestionado AWS)
    ↓ (Firehose consume automáticamente)
Kinesis Firehose (servicio gestionado AWS - configurado en otro módulo)
    ↓ (escribe directamente a S3)
S3 Bucket
    ↓
Amazon Personalize
```

**Endpoints necesarios en este módulo de networking:**
- ✅ `kinesis-streams` - Para que ECS envíe eventos (INCLUIDO)
- ✅ S3 Gateway Endpoint - Para acceso privado a S3 (YA INCLUIDO)

**Servicios configurados en otros módulos:**
- Kinesis Data Streams (el stream)
- Kinesis Firehose (el delivery stream)
- S3 Bucket
- Amazon Personalize

**Nota importante:** Kinesis Firehose es un servicio gestionado que corre fuera de tu VPC y puede escribir a S3 directamente sin necesidad de endpoint VPC.

### Endpoints NO incluidos

- ❌ `ecs` - No necesario porque Azure DevOps despliega desde fuera de la VPC
- ❌ `ecs-agent` - No necesario para Fargate (solo para ECS en EC2)
- ❌ `ecs-telemetry` - No necesario sin Container Insights

## Características de Seguridad

- **Conectividad Privada**: Acceso a servicios AWS mediante VPC Endpoints (PC-IAC-020)
- **Alta Disponibilidad**: 2 NAT Gateways (uno por AZ) con tablas de rutas independientes
- **Principio de Mínimo Privilegio**: Security Groups configurados con reglas restrictivas
- **Aislamiento de Red**: Subnets privadas sin acceso directo a Internet
- **Private DNS**: Habilitado en endpoints de tipo Interface para resolución de nombres
- **Optimizado para ECS Fargate**: Todos los endpoints necesarios para ejecutar contenedores sin NAT Gateway

## Uso

```hcl
module "networking" {
  source = "./networking"

  # Variables de gobernanza
  client      = "pragma"
  project     = "myproject"
  environment = "dev"
  region      = "us-east-1"

  # Configuración de VPC
  vpc_cidr             = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Configuración de subnets públicas
  public_subnets = {
    "public-1" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    }
    "public-2" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  }

  # Configuración de subnets privadas
  private_subnets = {
    "private-1" = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-east-1a"
    }
    "private-2" = {
      cidr_block        = "10.0.12.0/24"
      availability_zone = "us-east-1b"
    }
    "private-3" = {
      cidr_block        = "10.0.21.0/24"
      availability_zone = "us-east-1a"
    }
    "private-4" = {
      cidr_block        = "10.0.22.0/24"
      availability_zone = "us-east-1b"
    }
  }

  # VPC Endpoints optimizados para ECS Fargate con Kinesis
  interface_endpoints = [
    "ecr.api",           # ECR API - Obligatorio
    "ecr.dkr",           # ECR Docker - Obligatorio
    "secretsmanager",    # Secrets Manager
    "logs",              # CloudWatch Logs básicos
    "kinesis-streams"    # Kinesis Data Streams - Para enviar eventos
  ]
  enable_kinesis_firehose_endpoint = false  # true solo si tienes procesadores Lambda en VPC

  # Tags adicionales
  additional_tags = {
    Owner      = "CloudOps Team"
    CostCenter = "Engineering"
  }
}
```

## Inputs

| Nombre | Descripción | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| client | Nombre del cliente (máx 10 caracteres) | string | - | Sí |
| project | Nombre del proyecto (máx 15 caracteres) | string | - | Sí |
| environment | Ambiente de despliegue (dev, qa, pdn) | string | - | Sí |
| region | Región de AWS | string | "us-east-1" | No |
| vpc_cidr | CIDR block para la VPC | string | "10.0.0.0/16" | No |
| enable_dns_hostnames | Habilitar DNS hostnames | bool | true | No |
| enable_dns_support | Habilitar DNS support | bool | true | No |
| public_subnets | Configuración de subnets públicas | map(object) | Ver variables.tf | No |
| private_subnets | Configuración de subnets privadas | map(object) | Ver variables.tf | No |
| interface_endpoints | Lista de servicios para VPC Endpoints Interface | list(string) | ["ecr.api", "ecr.dkr", "secretsmanager", "logs", "kinesis-streams"] | No |
| additional_tags | Tags adicionales | map(string) | {} | No |

## Outputs

| Nombre | Descripción |
|--------|-------------|
| vpc_id | ID de la VPC creada |
| vpc_cidr | CIDR block de la VPC |
| vpc_arn | ARN de la VPC |
| internet_gateway_id | ID del Internet Gateway |
| public_subnet_ids | IDs de las subnets públicas |
| private_subnet_ids | IDs de las subnets privadas |
| nat_gateway_ids | IDs de los NAT Gateways |
| elastic_ip_addresses | Direcciones IP elásticas |
| public_route_table_id | ID de la tabla de rutas pública |
| private_route_table_id | ID de la tabla de rutas privada |
| s3_gateway_endpoint_id | ID del S3 Gateway Endpoint |
| interface_endpoint_ids | IDs de los VPC Endpoints Interface |
| vpc_endpoints_security_group_id | ID del Security Group para VPC Endpoints |
| networking_summary | Resumen de la infraestructura creada |

## Requisitos

- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- Credenciales de AWS configuradas

## Cumplimiento de Reglas PC-IAC

| Regla | Descripción | Implementación |
|-------|-------------|----------------|
| PC-IAC-002 | Variables de Gobernanza | Variables client, project, environment con validaciones |
| PC-IAC-003 | Nomenclatura Estándar | Prefijo de gobernanza en todos los recursos |
| PC-IAC-004 | Etiquetas Obligatorias | Tags comunes aplicados mediante merge |
| PC-IAC-010 | For_Each y Control | Uso de for_each para recursos múltiples |
| PC-IAC-020 | Seguridad (Hardenizado) | VPC Endpoints, Security Groups restrictivos |

## Decisiones de Diseño

### NAT Gateways por Availability Zone
Se crea un NAT Gateway por cada AZ única definida en las subnets públicas, garantizando alta disponibilidad y evitando puntos únicos de falla.

### VPC Endpoints
Se implementan VPC Endpoints para reducir costos de transferencia de datos y mejorar la seguridad al evitar tráfico por Internet público.

### Security Groups
El Security Group para VPC Endpoints solo permite tráfico HTTPS (443) desde el CIDR de la VPC, siguiendo el principio de mínimo privilegio.

## Autor

Pragma CloudOps Team

## Licencia

Proprietary - Pragma
