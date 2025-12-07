terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.21.0"
    }
  }
}


# 1. Database User
resource "mongodbatlas_database_user" "user" {
  username           = "workshop-user"
  password           = "secure-password-123" # In prod, use variables/secrets
  project_id         = var.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
}

# 2. IP Access List
resource "mongodbatlas_project_ip_access_list" "ip" {
  project_id = var.project_id
  cidr_block = "0.0.0.0/0" # Demo only!
  comment    = "Allow all for workshop demo"
}

# 3. Private Endpoint (GCP)
resource "mongodbatlas_privatelink_endpoint" "test" {
  project_id    = var.project_id
  provider_name = "GCP"
  region        = "EUROPE_NORTH_1"
}

# Generate a random password for the database user
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Standard Database User (SCRAM-SHA-1)
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


# Note: In a real scenario, you would also need mongodbatlas_privatelink_endpoint_service
# to link it to the actual GCP Forwarding Rule.
