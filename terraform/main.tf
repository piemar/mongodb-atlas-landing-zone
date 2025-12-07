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

provider "mongodbatlas" {
  public_key  = var.atlas_public_key
  private_key = var.atlas_private_key
}

provider "google" {
  project = var.gcp_project_id
  region  = "europe-north1"
}

# Retrieve an access token as the Terraform runner
data "google_client_config" "default" {}

# --- The Golden Path Module ---
module "standard_stack" {
  source            = "./modules/standard-stack"
  atlas_org_id      = var.atlas_org_id
  atlas_public_key  = var.atlas_public_key
  atlas_private_key = var.atlas_private_key
  gcp_project_id    = var.gcp_project_id
  project_name      = "SvenskaSpel-Workshop"
}

# Configure Kubernetes Provider to talk to the GKE cluster (Output from Stack)
provider "kubernetes" {
  host                   = "https://${module.standard_stack.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.standard_stack.cluster_ca_certificate)
}

# Create Kubernetes Secret with Atlas Credentials
resource "kubernetes_secret" "atlas_creds" {
  metadata {
    name = "atlas-creds"
  }

  data = {
    username              = module.standard_stack.db_username
    password              = module.standard_stack.db_password
    connection_string_gcp = module.standard_stack.connection_string_gcp
    connection_string_aws = module.standard_stack.connection_string_aws
  }

  depends_on = [module.standard_stack]
}
