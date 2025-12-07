terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      version = "1.21.0"
    }
  }
}

variable "org_id" {
  type = string
}

variable "project_name" {
  type = string
}

resource "mongodbatlas_project" "project" {
  name   = var.project_name
  org_id = var.org_id
}

output "project_id" {
  value = mongodbatlas_project.project.id
}
