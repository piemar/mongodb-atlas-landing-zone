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

# 1. Auditing
resource "mongodbatlas_auditing" "audit" {
  project_id                  = var.project_id
  audit_authorization_success = false # Log only failures for authz
  enabled                     = true
}

# 2. Maintenance Window
resource "mongodbatlas_maintenance_window" "window" {
  project_id  = var.project_id
  day_of_week = 7 # Sunday
  hour_of_day = 2 # 02:00 UTC
}

variable "cluster_name" {
  type = string
}

# 3. Backup Compliance Policy (PITR & Retention)
resource "mongodbatlas_cloud_backup_schedule" "backup" {
  project_id   = var.project_id
  cluster_name = var.cluster_name

  policy_item_hourly {
    frequency_interval = 6
    retention_unit     = "days"
    retention_value    = 7
  }

  policy_item_daily {
    frequency_interval = 1
    retention_unit     = "days"
    retention_value    = 30
  }
}

