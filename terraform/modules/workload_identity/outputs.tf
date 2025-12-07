output "gcp_service_account_email" {
  description = "The email of the created GCP Service Account"
  value       = google_service_account.app_sa.email
}
