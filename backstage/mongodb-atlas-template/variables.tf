variable "atlas_org_id" {
  type        = string
  description = "MongoDB Atlas Organization ID"
}

variable "atlas_public_key" {
  type        = string
  description = "MongoDB Atlas Public API Key"
}

variable "atlas_private_key" {
  type        = string
  description = "MongoDB Atlas Private API Key"
  sensitive   = true
}

variable "project_name" {
  type        = string
  description = "Name of the Atlas Project"
  default     = "${{ values.name }}"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Atlas Cluster"
  default     = "${{ values.name }}-cluster"
}

variable "region" {
  type        = string
  description = "GCP Region for the cluster"
  default     = "${{ values.region }}"
}

variable "instance_size" {
  type        = string
  description = "Cluster instance size (e.g., M10, M30)"
  default     = "${{ values.size }}"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID"
  default     = "${{ values.gcp_project_id }}"
}

variable "name" {
  type        = string
  description = "Application Name"
  default     = "${{ values.name }}"
}
