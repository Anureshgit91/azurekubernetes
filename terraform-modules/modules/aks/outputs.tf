output "aks_clusters" {
  description = "Information about created AKS clusters"
  value = {
    for cluster_name, cluster in azurerm_kubernetes_cluster.aks :
    cluster_name => {
      id                = cluster.id
      name              = cluster.name
      kube_config       = cluster.kube_config
      fqdn              = cluster.fqdn
      identity          = cluster.identity
    }
  }
  sensitive = true
}

output "cluster_names" {
  description = "Map of logical names to cluster names"
  value = {
    for cluster_name, cluster in azurerm_kubernetes_cluster.aks :
    cluster_name => cluster.name
  }
}

output "cluster_ids" {
  description = "Map of logical names to cluster IDs"
  value = {
    for cluster_name, cluster in azurerm_kubernetes_cluster.aks :
    cluster_name => cluster.id
  }
}

output "cluster_fqdns" {
  description = "FQDNs of the AKS clusters"
  value = {
    for cluster_name, cluster in azurerm_kubernetes_cluster.aks :
    cluster_name => cluster.fqdn
  }
}

output "node_resource_group_names" {
  description = "Resource group names for node pools"
  value = {
    for cluster_name, cluster in azurerm_kubernetes_cluster.aks :
    cluster_name => cluster.node_resource_group
  }
}

output "kubelet_identities" {
  description = "Kubelet identities"
  value = {
    for cluster_name, cluster in azurerm_kubernetes_cluster.aks :
    cluster_name => cluster.kubelet_identity
  }
}

output "node_pool_names" {
  description = "Node pool names created"
  value = {
    for pool_key, pool in azurerm_kubernetes_cluster_node_pool.node_pools :
    pool_key => pool.name
  }
}
