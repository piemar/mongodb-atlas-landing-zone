# Governance and Compliance Features

## Overview

This Landing Zone implements comprehensive governance controls to ensure security, compliance, and operational excellence.

## Auditing

### Configuration

```hcl
resource "mongodbatlas_auditing" "audit" {
  project_id                  = var.project_id
  audit_filter                = "{\"atype\":\"authenticate\",\"param\":{\"user\":\"app-user\"}}"
  audit_authorization_success = true
  enabled                     = true
}
```

### What Gets Audited

1. **Authentication Events**:
   - Successful logins
   - Failed login attempts
   - User creation/deletion
   - Role changes

2. **Authorization Events**:
   - Database access attempts
   - Collection access
   - Administrative operations

3. **Data Access**:
   - Read operations (optional)
   - Write operations
   - Delete operations
   - Schema changes

### Audit Log Format

```json
{
  "atype": "authenticate",
  "ts": {"$date": "2024-12-13T10:30:00.000Z"},
  "local": {"ip": "10.0.1.5", "port": 27017},
  "remote": {"ip": "10.0.2.10", "port": 54321},
  "users": [{"user": "app-user", "db": "admin"}],
  "roles": [{"role": "readWrite", "db": "wif_demo_db"}],
  "param": {"user": "app-user", "db": "admin", "mechanism": "SCRAM-SHA-256"},
  "result": 0
}
```

### Accessing Audit Logs

**Via Atlas UI:**
1. Navigate to Security → Audit Log
2. Filter by date range, user, or event type
3. Export to JSON or CSV

**Via API:**
```bash
curl -X GET \
  "https://cloud.mongodb.com/api/atlas/v2/groups/{PROJECT_ID}/auditLog" \
  -u "${ATLAS_PUBLIC_KEY}:${ATLAS_PRIVATE_KEY}"
```

### Compliance Use Cases

- **GDPR**: Track data access for specific users
- **SOC 2**: Demonstrate access controls and monitoring
- **HIPAA**: Audit all PHI access
- **PCI DSS**: Monitor privileged user activity

## Maintenance Windows

### Configuration

```hcl
resource "mongodbatlas_maintenance_window" "window" {
  project_id  = var.project_id
  day_of_week = 7  # Sunday
  hour_of_day = 2  # 02:00 UTC
}
```

### Purpose

**Controlled Updates:**
- MongoDB version upgrades
- Security patches
- Infrastructure maintenance
- Configuration changes

**Business Impact:**
- Scheduled during low-traffic periods
- Predictable maintenance schedule
- Minimizes disruption

### Maintenance Types

1. **Automatic Maintenance**:
   - Security patches
   - Minor version updates
   - Infrastructure updates

2. **Deferred Maintenance**:
   - Major version upgrades
   - Cluster tier changes
   - Region migrations

### Best Practices

1. **Choose Off-Peak Hours**: Sunday 02:00 UTC for European customers
2. **Notify Stakeholders**: Automated emails before maintenance
3. **Test in Non-Prod**: Apply updates to dev/staging first
4. **Monitor During Maintenance**: Watch for unexpected issues

## IP Access Lists

### Configuration

```hcl
resource "mongodbatlas_project_ip_access_list" "ip" {
  project_id = var.project_id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow all for workshop demo"
}
```

### Production Configuration

For production, use restrictive access:

```hcl
# Allow only GKE cluster
resource "mongodbatlas_project_ip_access_list" "gke" {
  project_id = var.project_id
  cidr_block = "10.0.0.0/16"  # GKE VPC CIDR
  comment    = "GKE Cluster Access"
}

# Allow office network
resource "mongodbatlas_project_ip_access_list" "office" {
  project_id = var.project_id
  cidr_block = "203.0.113.0/24"
  comment    = "Office Network"
}

# Allow VPN
resource "mongodbatlas_project_ip_access_list" "vpn" {
  project_id = var.project_id
  cidr_block = "198.51.100.0/24"
  comment    = "Corporate VPN"
}
```

### Security Groups (AWS)

For AWS deployments:

```hcl
resource "mongodbatlas_project_ip_access_list" "aws_sg" {
  project_id         = var.project_id
  aws_security_group = "sg-0123456789abcdef"
  comment            = "AWS Application Security Group"
}
```

## Monitoring Integration

### Datadog Integration

```hcl
resource "mongodbatlas_third_party_integration" "datadog" {
  project_id = var.project_id
  type       = "DATADOG"
  api_key    = var.datadog_api_key
  region     = "EU"
}
```

### Metrics Exported

1. **Performance Metrics**:
   - Operations per second
   - Query execution time
   - Index usage
   - Connection count

2. **Resource Metrics**:
   - CPU utilization
   - Memory usage
   - Disk IOPS
   - Network throughput

3. **Replication Metrics**:
   - Replication lag
   - Oplog window
   - Election events

### Alerting

**Critical Alerts:**
- CPU > 80% for 5 minutes
- Disk usage > 90%
- Replication lag > 10 seconds
- Connection pool exhaustion

**Warning Alerts:**
- Slow queries > 1000ms
- Index miss ratio > 10%
- Memory usage > 70%

## Encryption

### Encryption at Rest

**Enabled by Default:**
- All data encrypted with AES-256
- MongoDB-managed keys
- Automatic key rotation

**Customer-Managed Keys (BYOK):**
```hcl
resource "mongodbatlas_encryption_at_rest" "byok" {
  project_id = var.project_id

  google_cloud_kms_config {
    enabled                 = true
    service_account_key     = var.gcp_service_account_key
    key_version_resource_id = var.kms_key_id
  }
}
```

### Encryption in Transit

**TLS 1.2+ Required:**
- All connections encrypted
- Certificate validation enforced
- Perfect forward secrecy

**Connection String:**
```
mongodb+srv://cluster.mongodb.net/?tls=true&tlsAllowInvalidCertificates=false
```

## Network Security

### Private Endpoints

See [private-endpoints.md](./private-endpoints.md) for detailed configuration.

**Benefits:**
- No internet exposure
- Reduced attack surface
- Compliance with data residency requirements

### VPC Peering (Alternative)

For AWS/Azure:

```hcl
resource "mongodbatlas_network_peering" "peer" {
  project_id     = var.project_id
  container_id   = var.container_id
  provider_name  = "AWS"
  vpc_id         = var.vpc_id
  aws_account_id = var.aws_account_id
  route_table_cidr_block = "10.0.0.0/16"
}
```

## Database Access Controls

### Role-Based Access Control (RBAC)

```hcl
resource "mongodbatlas_database_user" "read_only" {
  username           = "analyst"
  password           = random_password.analyst_password.result
  project_id         = var.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "read"
    database_name = "analytics_db"
  }
}
```

### Custom Roles

```hcl
resource "mongodbatlas_custom_db_role" "app_role" {
  project_id = var.project_id
  role_name  = "customAppRole"

  actions {
    action = "FIND"
    resources {
      collection_name = "orders"
      database_name   = "production"
    }
  }

  actions {
    action = "INSERT"
    resources {
      collection_name = "orders"
      database_name   = "production"
    }
  }
}
```

## Compliance Certifications

### MongoDB Atlas Certifications

- **SOC 2 Type II**: Annual audit
- **ISO 27001**: Information security management
- **PCI DSS**: Payment card industry compliance
- **HIPAA**: Healthcare data protection
- **GDPR**: EU data protection
- **FedRAMP**: US government compliance

### Compliance Features

1. **Data Residency**:
   - Deploy in specific regions
   - Data never leaves region
   - Backups stored in same region

2. **Access Logging**:
   - All access logged
   - Immutable audit trail
   - Long-term retention

3. **Encryption**:
   - At rest (AES-256)
   - In transit (TLS 1.2+)
   - Customer-managed keys

4. **Network Isolation**:
   - Private endpoints
   - VPC peering
   - IP access lists

## Cost Governance

### Resource Tagging

```hcl
resource "mongodbatlas_advanced_cluster" "cluster" {
  # ... other config ...

  tags {
    key   = "Environment"
    value = "Production"
  }

  tags {
    key   = "CostCenter"
    value = "Engineering"
  }

  tags {
    key   = "Owner"
    value = "platform-team"
  }
}
```

### Budget Alerts

**Via Atlas UI:**
1. Navigate to Billing → Alerts
2. Set monthly budget threshold
3. Configure email notifications

**Thresholds:**
- Warning: 75% of budget
- Critical: 90% of budget
- Emergency: 100% of budget

### Cost Optimization

1. **Right-Size Clusters**:
   - Monitor CPU/memory usage
   - Scale down during off-peak
   - Use auto-scaling

2. **Optimize Storage**:
   - Enable compression
   - Archive old data
   - Use tiered storage

3. **Reduce Backup Costs**:
   - Adjust retention periods
   - Compress backups
   - Delete unused snapshots

## Operational Excellence

### Change Management

**All Changes via Terraform:**
```bash
# 1. Make changes in code
vim terraform/modules/cluster/main.tf

# 2. Plan changes
terraform plan

# 3. Review with team
git commit -m "Scale cluster to M20"
git push
# Create PR for review

# 4. Apply after approval
terraform apply
```

### Disaster Recovery

See [backup-policies.md](./backup-policies.md) for detailed DR procedures.

**Key Metrics:**
- **RTO**: 1 hour
- **RPO**: 5 minutes
- **Backup Frequency**: Continuous + daily snapshots

### Documentation

**Required Documentation:**
1. Architecture diagrams
2. Runbooks for common operations
3. Disaster recovery procedures
4. Security policies
5. Compliance evidence

## Governance Checklist

- [ ] Auditing enabled for all clusters
- [ ] Maintenance windows configured
- [ ] IP access lists restricted
- [ ] Monitoring integrated (Datadog/CloudWatch)
- [ ] Encryption at rest enabled
- [ ] TLS enforced for all connections
- [ ] Private endpoints configured
- [ ] RBAC implemented
- [ ] Backup policies configured
- [ ] DR procedures documented
- [ ] Cost alerts configured
- [ ] Resource tagging implemented
- [ ] Change management process defined
- [ ] Compliance requirements met
