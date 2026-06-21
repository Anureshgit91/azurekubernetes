locals {
  merged_tags = {
    for cluster_name, cluster_config in var.clusters :
    cluster_name => merge(
      var.common_tags,
      {
        environment = var.environment
        project     = var.project_name
        module      = "aks"
      },
      cluster_config.tags
    )
  }
}

# Create AKS Clusters
resource "azurerm_kubernetes_cluster" "aks" {
  for_each = var.clusters

  name                = format("%s-%s-%s-aks", var.project_name, each.key, var.environment)
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  dns_prefix          = format("%s-%s", var.project_name, each.key)
  kubernetes_version  = each.value.kubernetes_version

  tags = local.merged_tags[each.key]

  # Default Node Pool Configuration
  default_node_pool {
    name                = each.value.default_node_pool.name
    vm_size             = each.value.default_node_pool.vm_size
    enable_auto_scaling = each.value.default_node_pool.enable_auto_scaling
    node_count          = each.value.default_node_pool.enable_auto_scaling ? null : each.value.default_node_pool.node_count
    min_count           = each.value.default_node_pool.enable_auto_scaling ? each.value.default_node_pool.min_count : null
    max_count           = each.value.default_node_pool.enable_auto_scaling ? each.value.default_node_pool.max_count : null
    zones               = length(each.value.default_node_pool.availability_zones) > 0 ? each.value.default_node_pool.availability_zones : null

    tags = merge(
      local.merged_tags[each.key],
      each.value.default_node_pool.tags
    )
  }

  # Network Profile - Dynamic Block
  network_profile {
    network_plugin      = each.value.network_profile.network_plugin
    network_policy      = each.value.network_profile.network_policy
    service_cidr        = each.value.network_profile.service_cidr
    dns_service_ip      = each.value.network_profile.dns_service_ip
    pod_cidr            = each.value.network_profile.pod_cidr
    outbound_type       = each.value.network_profile.outbound_type
  }

  # Identity Configuration
  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.user_assigned_identity_id != null ? [each.value.identity.user_assigned_identity_id] : []
  }

  # RBAC Configuration
  role_based_access_control_enabled = each.value.rbac_enabled

  # Azure AD RBAC - Dynamic Block
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = each.value.rbac_enabled && length(each.value.azure_active_directory_role_based_access_control) > 0 ? [each.value.azure_active_directory_role_based_access_control] : []
    content {
      managed                   = azure_active_directory_role_based_access_control.value.managed
      tenant_id                 = azure_active_directory_role_based_access_control.value.tenant_id
      admin_group_object_ids    = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      azure_rbac_enabled        = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
    }
  }

  # Add-ons Configuration
  http_application_routing_enabled = each.value.addons.http_application_routing_enabled

  # OMS Agent configuration (only if enabled)
  dynamic "oms_agent" {
    for_each = each.value.addons.oms_agent_enabled ? [1] : []
    content {
      log_analytics_workspace_id = each.value.addons.monitoring_log_analytics_workspace_id
    }
  }

  # Auto-scaler Profile configuration (when supported)
  dynamic "auto_scaler_profile" {
    for_each = length(each.value.auto_scaler_profile) > 0 ? [each.value.auto_scaler_profile] : []
    content {
      balance_similar_node_groups    = auto_scaler_profile.value.balance_similar_node_groups
      empty_bulk_delete_max          = auto_scaler_profile.value.empty_bulk_delete_max
      expander                       = auto_scaler_profile.value.expander
      max_graceful_termination_sec   = auto_scaler_profile.value.max_graceful_termination_sec
      scale_down_delay_after_add     = auto_scaler_profile.value.scale_down_delay_after_add
      scale_down_delay_after_failure = auto_scaler_profile.value.scale_down_delay_after_failure
      scale_down_unneeded            = auto_scaler_profile.value.scale_down_unneeded
      skip_nodes_with_local_storage  = auto_scaler_profile.value.skip_nodes_with_local_storage
      skip_nodes_with_system_pods    = auto_scaler_profile.value.skip_nodes_with_system_pods
    }
  }

  # Maintenance window not supported in all configurations

  lifecycle {
    ignore_changes = [kubernetes_version]
  }
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "node_pools" {
  for_each = merge([
    for cluster_name, cluster_config in var.clusters : {
      for pool_name, pool_config in cluster_config.node_pools :
      "${cluster_name}/${pool_name}" => {
        cluster_name   = cluster_name
        pool_name      = pool_name
        pool_config    = pool_config
      }
    }
  ]...)

  name                  = substr(replace(replace(replace(lower(each.value.pool_name), "_", ""), "-", ""), ".", ""), 0, 12)
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[each.value.cluster_name].id
  vm_size               = each.value.pool_config.vm_size
  node_count            = each.value.pool_config.enable_auto_scaling ? null : each.value.pool_config.node_count
  min_count             = each.value.pool_config.enable_auto_scaling ? each.value.pool_config.min_count : null
  max_count             = each.value.pool_config.enable_auto_scaling ? each.value.pool_config.max_count : null
  enable_auto_scaling   = each.value.pool_config.enable_auto_scaling
  zones                 = length(each.value.pool_config.availability_zones) > 0 ? each.value.pool_config.availability_zones : null

  node_labels = each.value.pool_config.labels
  tags        = merge(local.merged_tags[each.value.cluster_name], each.value.pool_config.tags)
}

# Diagnostic Settings - Conditional Creation
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  for_each = var.enable_diagnostics ? var.clusters : {}

  name                       = format("%s-diag", azurerm_kubernetes_cluster.aks[each.key].name)
  target_resource_id         = azurerm_kubernetes_cluster.aks[each.key].id
  log_analytics_workspace_id = each.value.addons.monitoring_log_analytics_workspace_id

  # Dynamic Log Categories
  dynamic "enabled_log" {
    for_each = ["kube-apiserver", "kube-controller-manager", "kube-scheduler", "kube-audit"]
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

}
