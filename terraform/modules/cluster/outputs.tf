output "cluster_name" {
  value = mongodbatlas_advanced_cluster.cluster.name
}

output "connection_strings" {
  value = mongodbatlas_advanced_cluster.cluster.connection_strings
}
