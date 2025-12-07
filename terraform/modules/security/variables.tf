variable "project_id" {
  description = "The Atlas Project ID"
  type        = string
}

variable "oidc_gcp_service_account_email" {
  description = "The email of the GCP Service Account for OIDC"
  type        = string
}

variable "cluster_name" {
  description = "The name of the Atlas cluster (for scoping the database user)"
  type        = string
}
