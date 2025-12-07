output "private_link_id" {
  value = mongodbatlas_privatelink_endpoint.test.private_link_id
}

output "private_endpoint_service_name" {
  value = mongodbatlas_privatelink_endpoint.test.endpoint_service_name
}

output "service_attachment_names" {
  value = mongodbatlas_privatelink_endpoint.test.service_attachment_names
}

output "db_username" {
  value = mongodbatlas_database_user.app_user.username
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}
