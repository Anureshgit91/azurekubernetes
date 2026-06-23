# Output Resource Groups
output "resource_groups" {
  description = "Resource groups created"
  value       = module.resource_groups.resource_groups
}

output "managed_identities" {
  description = "Managed identities created"
  value       = module.resource_groups.managed_identities
}

# Output ACRs
output "container_registries" {
  description = "Container registries created"
  value       = module.acr.login_servers
}

output "acr_ids" {
  description = "ACR resource IDs"
  value       = module.acr.registry_ids
}

# Output AKS Clusters
output "aks_clusters" {
  description = "AKS clusters created"
  value       = module.aks.cluster_names
}

output "cluster_fqdns" {
  description = "AKS cluster FQDNs"
  value       = module.aks.cluster_fqdns
}

output "node_pools" {
  description = "Node pools created across all clusters"
  value       = module.aks.node_pool_names
}

# Export kubeconfig command examples
output "kubectl_config_commands" {
  description = "Commands to get kubeconfig for each cluster"
  value = {
    for cluster_name, cluster_id in module.aks.cluster_ids :
    cluster_name => "az aks get-credentials --resource-group ${module.resource_groups.resource_group_names["core"]} --name ${module.aks.cluster_names[cluster_name]} --overwrite-existing"
  }
}
