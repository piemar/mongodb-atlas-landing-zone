resource "google_container_cluster" "primary" {
  depends_on = [google_project_service.container]
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # Enable Autopilot for a managed, hands-off experience
  enable_autopilot = true

  network    = var.network_name
  subnetwork = var.subnet_name

  # Workload Identity is enabled by default in Autopilot, but explicit config doesn't hurt
  # workload_identity_config {
  #   workload_pool = "${var.project_id}.svc.id.goog"
  # }

  # Private Cluster Config (Optional but recommended)
  # private_cluster_config {
  #   enable_private_nodes    = true
  #   enable_private_endpoint = false # Keep public endpoint for demo ease of access
  # }

  deletion_protection = false # For demo purposes only
}
