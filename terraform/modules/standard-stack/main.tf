terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.21.0"
    }
    google = {
      source = "hashicorp/google"
      version = ">= 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

# --- Part 1: Foundation ---
module "foundation" {
  source     = "../foundation"
  org_id     = var.atlas_org_id
  project_name = var.project_name
}

# --- Part 2: Cluster (GCP - Private) ---
module "cluster" {
  source        = "../cluster"
  project_id    = module.foundation.project_id
  region        = "EUROPE_NORTH_1" # Finland
  cluster_name  = "gcp-finland-private"
  provider_name = "GCP"
}

# --- Part 2.5: Cluster (AWS - Public) ---
module "cluster_aws" {
  source        = "../cluster"
  project_id    = module.foundation.project_id
  region        = "EU_NORTH_1" # Stockholm
  cluster_name  = "aws-stockholm-public"
  provider_name = "AWS"
}

# --- Part 3: Workload Identity (GCP Side) ---
module "workload_identity" {
  source              = "../workload_identity"
  gcp_project_id      = var.gcp_project_id
  app_name            = "wif-demo-app"
  k8s_namespace       = "default"
  k8s_service_account = "wif-demo-sa"

  # The Identity Pool (svc.id.goog) is created by GKE, so we must wait for it.
  depends_on = [module.gke]
}

# --- Part 3.5: Security (Atlas Side) ---
module "security" {
  source                           = "../security"
  project_id                       = module.foundation.project_id
  oidc_gcp_service_account_email   = module.workload_identity.gcp_service_account_email
  cluster_name                     = module.cluster.cluster_name
}

# Allow Public Access for AWS Demo (0.0.0.0/0)
resource "mongodbatlas_project_ip_access_list" "allow_all" {
  project_id = module.foundation.project_id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow Public Access for AWS Latency Demo"
}

# --- Part 3.5: GCP Network (Private Endpoint Complete) ---
module "gcp_network" {
  source                  = "../gcp_network"
  gcp_project_id          = var.gcp_project_id
  atlas_project_id        = module.foundation.project_id
  private_link_id         = module.security.private_link_id
  service_attachment_names = module.security.service_attachment_names
}

# --- Part 3.6: GKE Autopilot Cluster ---
module "gke" {
  source       = "../gke"
  project_id   = var.gcp_project_id
  region       = "europe-north1"
  cluster_name = "atlas-demo-cluster"
  network_name = module.gcp_network.network_name
  subnet_name  = module.gcp_network.subnet_name
}

# --- Part 4: Advanced (Auditing & Maintenance) ---
module "advanced" {
  source       = "../advanced"
  project_id   = module.foundation.project_id
  cluster_name = module.cluster.cluster_name
  
  # Explicit dependency to ensure cluster is ready for backups
  depends_on = [module.cluster]
}

# --- Part 5: Integrations (Monitoring) ---
module "integrations" {
  source     = "../integrations"
  project_id = module.foundation.project_id
}

# --- Part 6: Sharding (Global Clusters) ---
# module "sharding" {
#   source     = "../sharding"
#   project_id = module.foundation.project_id
# }
