# Private Endpoint Configuration

## Overview

Private endpoints enable secure, low-latency connectivity between your GCP VPC and MongoDB Atlas without exposing traffic to the public internet.

## Why Private Endpoints?

### Security Benefits
1. **No Internet Exposure**: Database traffic never traverses the public internet
2. **Reduced Attack Surface**: Eliminates exposure to internet-based threats
3. **Compliance**: Meets regulatory requirements for data in transit
4. **Network Isolation**: Traffic stays within Google's private network backbone

### Performance Benefits
1. **Lower Latency**: Direct connection via Google's network (typically 1-5ms)
2. **Higher Throughput**: No internet bandwidth limitations
3. **Predictable Performance**: Dedicated network path
4. **No NAT Gateway Costs**: Traffic doesn't leave GCP

### Cost Benefits
1. **No Data Egress Charges**: Traffic between GCP regions stays on Google's network
2. **Reduced NAT Gateway Costs**: No need for internet gateway
3. **Lower Bandwidth Costs**: Private network pricing

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Customer GCP VPC (svenska-spel-demo)                        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ GKE Autopilot Cluster                                │  │
│  │                                                      │  │
│  │  ┌────────────────┐                                 │  │
│  │  │ Application    │                                 │  │
│  │  │ Pod            │                                 │  │
│  │  └────────┬───────┘                                 │  │
│  │           │                                         │  │
│  └───────────┼─────────────────────────────────────────┘  │
│              │                                             │
│  ┌───────────▼─────────────────────────────────────────┐  │
│  │ Private Service Connect Endpoint                    │  │
│  │ (50 forwarding rules to Atlas service attachments)  │  │
│  └───────────┬─────────────────────────────────────────┘  │
│              │                                             │
└──────────────┼─────────────────────────────────────────────┘
               │ Private Connection
               │ (Google's Network Backbone)
               │
┌──────────────▼─────────────────────────────────────────────┐
│ MongoDB Atlas VPC (Managed by MongoDB)                     │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Private Link Service Attachment                      │  │
│  │ (Accepts connections from customer VPCs)             │  │
│  └───────────┬──────────────────────────────────────────┘  │
│              │                                             │
│  ┌───────────▼──────────────────────────────────────────┐  │
│  │ MongoDB Atlas Cluster (M10)                          │  │
│  │ Region: europe-north1 (Finland)                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### 1. Atlas Private Link Endpoint

Created in the `security` module:

```hcl
resource "mongodbatlas_privatelink_endpoint" "test" {
  project_id   = var.project_id
  provider_name = "GCP"
  region        = "EUROPE_NORTH_1"
}
```

**What This Creates:**
- Service attachment in MongoDB's VPC
- List of 50 service attachment names (for high availability)
- Private Link ID for reference

### 2. GCP Private Service Connect

Created in the `gcp_network` module:

```hcl
# Create IP addresses for each service attachment
resource "google_compute_address" "endpoint_ip" {
  count        = length(var.service_attachment_names)
  name         = "atlas-endpoint-ip-${count.index}"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.subnet.id
  region       = var.region
}

# Create forwarding rules to Atlas service attachments
resource "google_compute_forwarding_rule" "endpoint_rule" {
  count                 = length(var.service_attachment_names)
  name                  = "atlas-forwarding-rule-${count.index}"
  region                = var.region
  ip_address            = google_compute_address.endpoint_ip[count.index].id
  network               = google_compute_network.vpc.id
  target                = var.service_attachment_names[count.index]
  load_balancing_scheme = ""
}
```

**What This Creates:**
- 50 internal IP addresses in your VPC
- 50 forwarding rules pointing to Atlas service attachments
- DNS resolution for Atlas cluster endpoints

### 3. Complete the Connection

```hcl
resource "mongodbatlas_privatelink_endpoint_service" "link" {
  project_id          = var.atlas_project_id
  private_link_id     = var.private_link_id
  provider_name       = "GCP"
  endpoint_service_id = google_compute_forwarding_rule.endpoint_rule[0].id

  dynamic "endpoints" {
    for_each = google_compute_forwarding_rule.endpoint_rule
    content {
      ip_address    = google_compute_address.endpoint_ip[endpoints.key].address
      endpoint_name = endpoints.value.name
    }
  }
}
```

## Connection String

### Private Endpoint Connection String
```
mongodb+srv://app-user:password@gcp-finland-private-pl-0.mongodb.net/wif_demo_db
```

**Key Difference:**
- `-pl-0` suffix indicates private link endpoint
- Resolves to internal IP addresses (10.x.x.x)
- Traffic never leaves Google's network

### Public Endpoint Connection String (for comparison)
```
mongodb+srv://app-user:password@aws-stockholm-public.mongodb.net/wif_demo_db
```

**Characteristics:**
- Resolves to public IP addresses
- Traffic goes over the internet
- Higher latency, lower security

## Verification

### Test Private Connectivity

```bash
# Get a pod shell
kubectl exec -it <pod-name> -- /bin/sh

# Test DNS resolution
nslookup gcp-finland-private-pl-0.mongodb.net

# Should return internal IPs like:
# Name:   gcp-finland-private-pl-0.mongodb.net
# Address: 10.0.1.10
# Address: 10.0.1.11
# ...

# Test connectivity
nc -zv gcp-finland-private-pl-0.mongodb.net 27017
```

### Compare Latency

```bash
# Private endpoint (GCP)
time mongosh "mongodb+srv://gcp-finland-private-pl-0.mongodb.net" --eval "db.runCommand({ping:1})"
# Typical: 1-5ms

# Public endpoint (AWS)
time mongosh "mongodb+srv://aws-stockholm-public.mongodb.net" --eval "db.runCommand({ping:1})"
# Typical: 10-30ms
```

## Troubleshooting

### Connection Timeout

**Symptom**: Application cannot connect to Atlas via private endpoint

**Checks:**
1. Verify forwarding rules are created:
   ```bash
   gcloud compute forwarding-rules list --filter="name~atlas"
   ```

2. Check DNS resolution:
   ```bash
   kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup gcp-finland-private-pl-0.mongodb.net
   ```

3. Verify private endpoint status in Atlas UI:
   - Navigate to Network Access → Private Endpoint
   - Status should be "Available"

### High Latency

**Symptom**: Private endpoint has unexpectedly high latency

**Causes:**
1. Cross-region traffic (cluster and VPC in different regions)
2. Network congestion
3. Using public endpoint instead of private

**Solution:**
```bash
# Verify you're using the private endpoint
kubectl get secret atlas-creds -o jsonpath='{.data.MONGODB_URI_GCP}' | base64 -d
# Should contain "-pl-0" in the hostname
```

## Cost Considerations

### GCP Costs
- **Private Service Connect Endpoint**: ~$0.01/hour per endpoint
- **Data Transfer**: Free within same region
- **Cross-Region**: Standard GCP inter-region pricing

### MongoDB Atlas Costs
- **Private Endpoint**: No additional charge
- **Data Transfer**: Included in cluster pricing

### Cost Comparison

| Scenario | Monthly Cost (estimate) |
|----------|------------------------|
| Public endpoint + NAT Gateway | $45-100 |
| Private endpoint (same region) | $7-15 |
| **Savings** | **$30-85/month** |

## Best Practices

1. **Same Region Deployment**: Deploy GKE and Atlas cluster in the same region for lowest latency
2. **Multiple Endpoints**: Use all 50 service attachments for high availability
3. **DNS Caching**: Configure appropriate TTL for DNS resolution
4. **Monitoring**: Set up alerts for endpoint availability
5. **Firewall Rules**: Restrict access to private endpoint IPs only

## Advanced: Multi-Region Setup

For multi-region deployments:

```hcl
# Create private endpoints in each region
resource "mongodbatlas_privatelink_endpoint" "eu_north" {
  project_id   = var.project_id
  provider_name = "GCP"
  region        = "EUROPE_NORTH_1"
}

resource "mongodbatlas_privatelink_endpoint" "eu_west" {
  project_id   = var.project_id
  provider_name = "GCP"
  region        = "EUROPE_WEST_1"
}
```

This enables applications in multiple regions to connect via their local private endpoint, minimizing latency.
