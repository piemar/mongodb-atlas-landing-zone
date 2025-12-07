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

# Example: Datadog Integration (Mocked keys)
# In a real demo, you would use valid API keys or show the GCP integration
resource "mongodbatlas_third_party_integration" "datadog" {
  project_id = var.project_id
  type       = "DATADOG"
  api_key    = "1234567890abcdef1234567890abcdef" # Valid 32-char hex format
  region     = "EU"
}
