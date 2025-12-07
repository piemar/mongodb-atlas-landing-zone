terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">= 4.0"
    }
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.21.0"
    }
  }
}

variable "gcp_project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-north1"
}

variable "atlas_project_id" {
  type = string
}

variable "private_link_id" {
  type = string
}

variable "service_attachment_names" {
  type = list(string)
}

# 1. VPC Network
resource "google_compute_network" "vpc" {
  name                    = "atlas-demo-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

# 2. Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "atlas-demo-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.gcp_project_id
}

# 3. GCP Internal Address for the Endpoint (One per service attachment)
resource "google_compute_address" "endpoint_ip" {
  count        = length(var.service_attachment_names)
  name         = "atlas-endpoint-ip-${count.index}"
  subnetwork   = google_compute_subnetwork.subnet.id
  address_type = "INTERNAL"
  region       = var.region
  project      = var.gcp_project_id
}

# 4. GCP Forwarding Rule (One per service attachment)
resource "google_compute_forwarding_rule" "endpoint_rule" {
  count                 = length(var.service_attachment_names)
  name                  = "atlas-forwarding-rule-${count.index}"
  target                = var.service_attachment_names[count.index]
  network               = google_compute_network.vpc.id
  subnetwork            = google_compute_subnetwork.subnet.id
  ip_address            = google_compute_address.endpoint_ip[count.index].id
  load_balancing_scheme = "" # Required for PSC
  project               = var.gcp_project_id
  region                = var.region
}

# 5. Link Atlas to GCP Endpoint
resource "mongodbatlas_privatelink_endpoint_service" "link" {
  project_id          = var.atlas_project_id
  private_link_id     = var.private_link_id
  endpoint_service_id = google_compute_forwarding_rule.endpoint_rule[0].name # Just needs one ID to identify the service
  provider_name       = "GCP"
  gcp_project_id      = var.gcp_project_id

  dynamic "endpoints" {
    for_each = range(length(var.service_attachment_names))
    content {
      ip_address    = google_compute_address.endpoint_ip[endpoints.value].address
      endpoint_name = google_compute_forwarding_rule.endpoint_rule[endpoints.value].name
    }
  }
}
