output "cluster_endpoint" {
  value = module.gke.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.gke.cluster_ca_certificate
}

output "db_username" {
  value = module.security.db_username
}

output "db_password" {
  value = module.security.db_password
}

output "connection_string_gcp" {
  value = "mongodb+srv://${module.security.db_username}:${module.security.db_password}@${replace(module.cluster.connection_strings[0].standard_srv, "mongodb+srv://", "")}/wif_demo_db?retryWrites=true&w=majority"
}

output "connection_string_aws" {
  value = "mongodb+srv://${module.security.db_username}:${module.security.db_password}@${replace(module.cluster_aws.connection_strings[0].standard_srv, "mongodb+srv://", "")}/wif_demo_db?retryWrites=true&w=majority"
}
