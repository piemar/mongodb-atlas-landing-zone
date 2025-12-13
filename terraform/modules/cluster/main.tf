terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.21.0"
    }
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
} 

variable "cluster_name" {
  type = string
  default = "workshop-cluster"
}

variable "provider_name" {
  type    = string
  default = "GCP"
}

resource "mongodbatlas_advanced_cluster" "cluster" {
  project_id   = var.project_id
  name         = var.cluster_name
  cluster_type = "REPLICASET"
  
  replication_specs {
    region_configs {
      electable_specs {
        instance_size = "M10"
        node_count    = 3
      }
      provider_name = var.provider_name
      region_name   = var.region
      priority      = 7
    }
  }

  # Pinning the version as requested
  mongo_db_major_version = "8.0"
  
  # Enable Backups (Required for Backup Schedule)
  backup_enabled = true

  # Enable Termination Protection
  termination_protection_enabled = false # Set to true in prod
}
