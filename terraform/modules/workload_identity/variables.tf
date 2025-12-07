variable "gcp_project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "app_name" {
  description = "The name of the application (used for GCP Service Account)"
  type        = string
}

variable "k8s_namespace" {
  description = "The Kubernetes namespace where the app will run"
  type        = string
  default     = "default"
}

variable "k8s_service_account" {
  description = "The Kubernetes Service Account name"
  type        = string
  default     = "default"
}
