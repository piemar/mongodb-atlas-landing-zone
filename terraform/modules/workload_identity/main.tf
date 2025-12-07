resource "google_service_account" "app_sa" {
  account_id   = "${var.app_name}-sa"
  display_name = "Service Account for ${var.app_name} Workload Identity"
  project      = var.gcp_project_id
}

resource "google_service_account_iam_binding" "workload_identity_user" {
  service_account_id = google_service_account.app_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"
  ]
}
