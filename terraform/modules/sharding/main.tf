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

# Example of a Global Cluster (Sharded)
resource "mongodbatlas_advanced_cluster" "global_cluster" {
  project_id   = var.project_id
  name         = "global-sharded-cluster"
  cluster_type = "GEOSHARDED"

  # Zone 1: Europe (Finland)
  replication_specs {
    zone_name = "Europe Zone"
    region_configs {
      electable_specs {
        instance_size = "M30"
        node_count    = 3
      }
      provider_name = "GCP"
      region_name   = "EUROPE_NORTH_1"
      priority      = 7
    }
  }

  # Zone 2: Americas (US Central)
  # Note: For Global Clusters, ensure the instance size supports the region.
  replication_specs {
    zone_name = "Americas Zone"
    region_configs {
      electable_specs {
        instance_size = "M30"
        node_count    = 3
      }
      provider_name = "GCP"
      region_name   = "US_EAST_1"
      priority      = 7
    }
  }
}
