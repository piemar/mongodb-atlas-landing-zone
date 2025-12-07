variable "atlas_public_key" {
  description = "MongoDB Atlas Public API Key"
  type        = string
}

variable "atlas_private_key" {
  description = "MongoDB Atlas Private API Key"
  type        = string
  sensitive   = true
}

variable "atlas_org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
}

variable "gcp_project_id" {
  description = "Google Cloud Project ID"
  type        = string
}
