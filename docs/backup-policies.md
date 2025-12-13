# Backup Policies and Disaster Recovery

## Overview

This Landing Zone implements automated, continuous backups with point-in-time recovery capabilities using MongoDB Atlas Cloud Backup.

## Backup Configuration

### Automated Backup Schedule

Configured in the `advanced` module:

```hcl
resource "mongodbatlas_cloud_backup_schedule" "backup" {
  project_id   = var.project_id
  cluster_name = var.cluster_name

  # Continuous Cloud Backup (Oplog)
  reference_hour_of_day    = 3
  reference_minute_of_hour = 30
  restore_window_days      = 7

  # Daily snapshots
  policy_item_daily {
    frequency_interval = 1
    retention_unit     = "days"
    retention_value    = 7
  }

  # Weekly snapshots
  policy_item_weekly {
    frequency_interval = 6  # Saturday
    retention_unit     = "weeks"
    retention_value    = 4
  }

  # Monthly snapshots
  policy_item_monthly {
    frequency_interval = 1  # First day of month
    retention_unit     = "months"
    retention_value    = 12
  }
}
```

## Backup Types

### 1. Continuous Cloud Backup (Oplog-based)

**How It Works:**
- MongoDB Atlas continuously captures oplog entries
- Enables point-in-time recovery to any second within the retention window
- No performance impact on production workloads

**Retention:**
- **7 days** of continuous backup
- Can restore to any point in time within this window

**Use Cases:**
- Recovering from accidental data deletion
- Rolling back bad deployments
- Investigating data corruption

**Example Recovery:**
```bash
# Restore to 2 hours ago
Restore Time: 2024-12-13 11:00:00 UTC
```

### 2. Daily Snapshots

**Schedule:**
- Taken at **03:30 UTC** every day
- Retained for **7 days**

**Storage:**
- Full snapshot of entire cluster
- Compressed and encrypted
- Stored in MongoDB's cloud storage

**Use Cases:**
- Daily recovery points
- Compliance requirements
- Testing with production-like data

### 3. Weekly Snapshots

**Schedule:**
- Taken every **Saturday**
- Retained for **4 weeks**

**Use Cases:**
- Weekly recovery points
- Longer-term data retention
- Compliance audits

### 4. Monthly Snapshots

**Schedule:**
- Taken on the **1st of each month**
- Retained for **12 months**

**Use Cases:**
- Long-term archival
- Annual compliance requirements
- Year-over-year analysis

## Backup Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ MongoDB Atlas Cluster (Production)                          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Oplog (Continuous Capture)                           │  │
│  │ • Every write operation captured                     │  │
│  │ • 7-day retention window                             │  │
│  │ • Point-in-time recovery                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Snapshot Schedule                                    │  │
│  │ • Daily: 03:30 UTC (7 days retention)                │  │
│  │ • Weekly: Saturday (4 weeks retention)               │  │
│  │ • Monthly: 1st of month (12 months retention)        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Encrypted Transfer
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ MongoDB Cloud Backup Storage                                │
│ • Encrypted at rest (AES-256)                               │
│ • Geo-redundant storage                                     │
│ • Immutable backups                                         │
│ • Automatic lifecycle management                            │
└─────────────────────────────────────────────────────────────┘
```

## Recovery Procedures

### Point-in-Time Recovery

**Scenario**: Accidental data deletion at 10:30 AM

**Steps:**
1. Navigate to Atlas UI → Backup → Restore
2. Select "Point in Time"
3. Choose timestamp: 10:29 AM (1 minute before deletion)
4. Select restore target:
   - New cluster (recommended for validation)
   - Download to local
   - Restore to existing cluster (overwrites data)

**Recovery Time:**
- Small clusters (<10GB): 5-15 minutes
- Medium clusters (10-100GB): 15-45 minutes
- Large clusters (>100GB): 1-3 hours

### Snapshot Recovery

**Scenario**: Need to restore from yesterday's backup

**Steps:**
1. Navigate to Atlas UI → Backup → Snapshots
2. Select yesterday's daily snapshot
3. Click "Restore"
4. Choose restore target

**Advantages:**
- Faster than point-in-time for large datasets
- Known good state
- Can be automated via API

## Backup Verification

### Automated Testing

```bash
# Test restore to a new cluster (monthly)
curl -X POST "https://cloud.mongodb.com/api/atlas/v2/groups/{PROJECT_ID}/clusters/{CLUSTER_NAME}/backup/restoreJobs" \
  -u "${ATLAS_PUBLIC_KEY}:${ATLAS_PRIVATE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "deliveryType": "automated",
    "targetClusterName": "restore-test-cluster",
    "snapshotId": "latest"
  }'
```

### Manual Verification

1. **Monthly Restore Test**:
   - Restore latest snapshot to test cluster
   - Verify data integrity
   - Run application tests
   - Delete test cluster

2. **Quarterly DR Drill**:
   - Simulate complete cluster failure
   - Restore to new cluster
   - Update application connection strings
   - Verify full functionality

## Compliance and Retention

### Retention Summary

| Backup Type | Frequency | Retention | Use Case |
|-------------|-----------|-----------|----------|
| Continuous (Oplog) | Real-time | 7 days | Point-in-time recovery |
| Daily Snapshot | Daily at 03:30 UTC | 7 days | Daily recovery points |
| Weekly Snapshot | Saturday | 4 weeks | Weekly recovery points |
| Monthly Snapshot | 1st of month | 12 months | Long-term archival |

### Compliance Considerations

**GDPR:**
- Backups can be deleted on request
- Encryption at rest and in transit
- Geo-redundant storage in EU regions

**SOC 2:**
- Automated backup verification
- Immutable backups
- Audit trail of all restore operations

**HIPAA:**
- Encrypted backups (AES-256)
- Access controls and logging
- Business Associate Agreement available

## Cost Optimization

### Backup Storage Costs

**Pricing Model:**
- Charged per GB of backup storage
- Compressed and deduplicated
- Varies by cloud provider and region

**Example Costs** (GCP europe-north1):
- 100GB cluster → ~30GB backup storage
- Daily snapshots: 30GB × 7 = 210GB
- Weekly snapshots: 30GB × 4 = 120GB
- Monthly snapshots: 30GB × 12 = 360GB
- **Total**: ~690GB backup storage
- **Cost**: ~$17/month

### Optimization Strategies

1. **Adjust Retention Periods**:
   ```hcl
   policy_item_daily {
     retention_value = 3  # Reduce from 7 to 3 days
   }
   ```

2. **Reduce Snapshot Frequency**:
   ```hcl
   policy_item_weekly {
     frequency_interval = 7  # Only 1 weekly snapshot
   }
   ```

3. **Compress Data**:
   - Use MongoDB compression (Snappy/Zstandard)
   - Reduces backup size by 60-80%

## Monitoring and Alerts

### Backup Health Checks

```hcl
resource "mongodbatlas_alert_configuration" "backup_failed" {
  project_id = var.project_id
  event_type = "BACKUP_FAILED"
  enabled    = true

  notification {
    type_name     = "EMAIL"
    email_address = "ops@svenskaspel.se"
    delay_min     = 0
  }
}
```

### Metrics to Monitor

1. **Backup Success Rate**: Should be 100%
2. **Backup Duration**: Increasing trend indicates growth
3. **Storage Growth**: Plan capacity accordingly
4. **Last Successful Backup**: Alert if >25 hours old

## Disaster Recovery Plan

### RTO and RPO

**Recovery Time Objective (RTO):**
- Target: 1 hour
- Actual: 15-45 minutes for typical clusters

**Recovery Point Objective (RPO):**
- Target: 5 minutes
- Actual: Real-time (continuous backup)

### DR Runbook

1. **Detect Failure**:
   - Monitoring alerts trigger
   - Verify cluster is truly down

2. **Assess Damage**:
   - Data corruption? → Point-in-time restore
   - Complete failure? → Snapshot restore
   - Region outage? → Restore to different region

3. **Initiate Restore**:
   ```bash
   # Via Atlas UI or API
   POST /api/atlas/v2/groups/{PROJECT_ID}/clusters/{CLUSTER_NAME}/backup/restoreJobs
   ```

4. **Update Application**:
   ```bash
   # Update Kubernetes secret with new connection string
   kubectl patch secret atlas-creds -p '{"data":{"MONGODB_URI":"<new-uri>"}}'
   
   # Restart pods
   kubectl rollout restart deployment/my-app
   ```

5. **Verify Recovery**:
   - Run smoke tests
   - Check data integrity
   - Monitor application logs

6. **Post-Mortem**:
   - Document incident
   - Update runbook
   - Improve monitoring

## Advanced Features

### Cross-Region Backups

For additional redundancy:

```hcl
resource "mongodbatlas_cloud_backup_schedule" "backup" {
  # ... existing config ...
  
  copy_settings {
    cloud_provider = "GCP"
    region_name    = "EUROPE_WEST_1"  # Different from cluster region
    should_copy_oplogs = true
  }
}
```

### Backup Encryption

All backups are encrypted with:
- **At Rest**: AES-256 encryption
- **In Transit**: TLS 1.2+
- **Key Management**: MongoDB-managed or customer-managed keys (BYOK)

### Queryable Backups

Download snapshots and query locally:

```bash
# Download snapshot
mongorestore --uri="mongodb://localhost:27017" --archive=snapshot.archive

# Query historical data
mongosh --eval "db.orders.find({date: '2024-01-01'})"
```

## Best Practices

1. **Test Restores Regularly**: Monthly restore tests to non-production
2. **Monitor Backup Health**: Set up alerts for failed backups
3. **Document Procedures**: Keep DR runbook up to date
4. **Automate Where Possible**: Use Terraform for backup configuration
5. **Encrypt Sensitive Data**: Use field-level encryption for PII
6. **Audit Access**: Log all backup and restore operations
7. **Plan for Growth**: Monitor backup storage trends
