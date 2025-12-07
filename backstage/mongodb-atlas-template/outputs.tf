output "connection_string" {
  value = mongodbatlas_advanced_cluster.cluster.connection_strings[0].standard_srv
}

output "project_id" {
  value = mongodbatlas_project.project.id
}
