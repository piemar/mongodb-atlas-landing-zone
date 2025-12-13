# Database User Management

## Overview

This Landing Zone implements secure, automated database user management with credential injection into Kubernetes workloads.

## How Database Users Are Created

### 1. Terraform Provisioning

Database users are created via the `security` module in Terraform:

```hcl
resource "mongodbatlas_database_user" "app_user" {
  username           = "app-user"
  password           = random_password.db_password.result
  project_id         = var.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "wif_demo_db"
  }
}
```

**Key Features:**
- **Random Password Generation**: Uses Terraform's `random_password` resource for secure, unique passwords
- **Least Privilege**: Users get only the permissions they need (`readWrite` on specific database)
- **No Hardcoded Credentials**: Passwords are generated at apply time and stored in Terraform state

### 2. Credential Storage in Kubernetes

Credentials are automatically injected into Kubernetes as secrets:

```hcl
resource "kubernetes_secret" "atlas_creds" {
  metadata {
    name      = "atlas-creds"
    namespace = "default"
  }

  data = {
    MONGODB_URI_GCP = module.standard_stack.connection_string_gcp
    MONGODB_URI_AWS = module.standard_stack.connection_string_aws
    DB_USERNAME     = module.standard_stack.db_username
    DB_PASSWORD     = module.standard_stack.db_password
  }
}
```

**Security Benefits:**
- Credentials never appear in application code
- Secrets are encrypted at rest in etcd
- Can be rotated without redeploying applications

### 3. Application Access

Applications consume credentials via environment variables:

```yaml
env:
  - name: MONGODB_URI_GCP
    valueFrom:
      secretKeyRef:
        name: atlas-creds
        key: MONGODB_URI_GCP
  - name: MONGODB_URI_AWS
    valueFrom:
      secretKeyRef:
        name: atlas-creds
        key: MONGODB_URI_AWS
```

**Application Code:**
```javascript
const mongoClientGCP = new MongoClient(process.env.MONGODB_URI_GCP);
const mongoClientAWS = new MongoClient(process.env.MONGODB_URI_AWS);
```

## User Types

### App User (`app-user`)
- **Purpose**: Application database access
- **Permissions**: `readWrite` on `wif_demo_db`
- **Scope**: Project-wide (can access all clusters)
- **Use Case**: Production applications

### Workshop User (`workshop-user`)
- **Purpose**: Administrative access for demos
- **Permissions**: `readWriteAnyDatabase`
- **Scope**: All databases in the project
- **Use Case**: Demonstrations and testing

## Security Best Practices Implemented

1. **No Cluster Scoping**: Users can access all clusters in the project (required for multi-cluster demos)
2. **Strong Passwords**: 16-character random passwords with mixed case and numbers
3. **Principle of Least Privilege**: App users get minimal required permissions
4. **Automated Rotation**: Passwords can be rotated by running `terraform apply` with new random seed
5. **Audit Trail**: All user access is logged via MongoDB Atlas auditing

## Credential Rotation

To rotate database credentials:

```bash
# 1. Taint the password resource
terraform taint module.standard_stack.module.security.random_password.db_password

# 2. Apply to generate new password and update Kubernetes secret
terraform apply

# 3. Restart pods to pick up new credentials
kubectl rollout restart deployment/my-app
```

## Troubleshooting

### Authentication Failed
**Symptom**: `MongoServerError: Authentication failed`

**Causes:**
1. User doesn't have access to the cluster (check scopes)
2. Password mismatch between Atlas and Kubernetes secret
3. IP not in access list

**Solution:**
```bash
# Verify secret contents
kubectl get secret atlas-creds -o jsonpath='{.data.DB_PASSWORD}' | base64 -d

# Check Atlas user configuration
terraform state show module.standard_stack.module.security.mongodbatlas_database_user.app_user
```

### Connection Timeout
**Symptom**: Connection hangs or times out

**Causes:**
1. Private endpoint not configured correctly
2. Network connectivity issues
3. IP access list blocking connection

**Solution:**
```bash
# Test connectivity from pod
kubectl exec -it <pod-name> -- curl -v telnet://cluster-endpoint:27017
```

## Advanced: Workload Identity Federation (Future)

For production environments, consider replacing database passwords with Workload Identity Federation:

```hcl
resource "mongodbatlas_database_user" "wif_user" {
  username           = "wif-user"
  project_id         = var.project_id
  auth_database_name = "$external"
  
  oidc_auth_type = "IDP_GROUP"
  
  roles {
    role_name     = "readWrite"
    database_name = "production_db"
  }
}
```

**Benefits:**
- No passwords to manage or rotate
- Automatic credential expiration
- Integration with GCP IAM
- Audit trail via Cloud Logging
