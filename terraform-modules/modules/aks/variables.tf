variable "clusters" {
  description = "Map of AKS clusters to create with comprehensive configuration"
  type = map(object({
    resource_group_name = string
    location            = string
    kubernetes_version  = optional(string, null)
    
    # Core cluster configuration
    network_profile = object({
      network_plugin      = optional(string, "azure")
      network_policy      = optional(string, null)
      service_cidr        = optional(string, "10.0.0.0/16")
      dns_service_ip      = optional(string, "10.0.0.10")
      pod_cidr            = optional(string, null)
      docker_bridge_cidr  = optional(string, null)
      outbound_type       = optional(string, "loadBalancer")
    })
    
    # Default Node Pool
    default_node_pool = object({
      name                = optional(string, "system")
      vm_size             = string
      node_count          = optional(number, 3)
      min_count           = optional(number, 1)
      max_count           = optional(number, 5)
      enable_auto_scaling = optional(bool, true)
      availability_zones  = optional(list(number), [])
      tags                = optional(map(string), {})
    })
    
    # Additional Node Pools
    node_pools = optional(map(object({
      vm_size             = string
      node_count          = optional(number, 1)
      min_count           = optional(number, 1)
      max_count           = optional(number, 5)
      enable_auto_scaling = optional(bool, true)
      availability_zones  = optional(list(number), [])
      labels              = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
      tags = optional(map(string), {})
    })), {})
    
    # Identity configuration
    identity = optional(object({
      type                      = optional(string, "SystemAssigned")
      user_assigned_identity_id = optional(string)
    }), {})
    
    # RBAC and Authentication
    rbac_enabled = optional(bool, true)
    azure_active_directory_role_based_access_control = optional(object({
      managed                = optional(bool, true)
      tenant_id              = optional(string)
      admin_group_object_ids = optional(list(string), [])
      azure_rbac_enabled     = optional(bool, true)
    }), {})
    
    # Add-ons
    addons = optional(object({
      http_application_routing_enabled  = optional(bool, false)
      ingress_application_gateway_enabled = optional(bool, false)
      monitoring_enabled                = optional(bool, true)
      monitoring_log_analytics_workspace_id = optional(string)
      oms_agent_enabled                 = optional(bool, true)
    }), {})
    
    # Network security
    network_security_group_id = optional(string)
    virtual_network_subnet_id = optional(string)
    
    # Auto-scaling and maintenance
    auto_scaler_profile = optional(object({
      balance_similar_node_groups      = optional(bool, true)
      empty_bulk_delete_max            = optional(number, 10)
      expander                         = optional(string, "priority")
      max_graceful_termination_sec     = optional(number, 600)
      max_node_provision_time          = optional(string, "15m")
      max_total_unready_percentage     = optional(number, 45)
      new_pod_scale_down_enabled       = optional(bool, true)
      scale_down_delay_after_add       = optional(string, "10m")
      scale_down_delay_after_failure   = optional(string, "3m")
      scale_down_delay_after_delete    = optional(string, "10s")
      scale_down_unneeded              = optional(string, "10m")
      scale_down_unready               = optional(string, "20m")
      skip_nodes_with_local_storage    = optional(bool, true)
      skip_nodes_with_system_pods      = optional(bool, true)
    }), {})
    
    # Maintenance window
    maintenance_window = optional(object({
      allowed = optional(list(object({
        day   = string
        hours = list(number)
      })), [])
      not_allowed = optional(list(object({
        start = string
        end   = string
      })), [])
    }), {})
    
    tags = optional(map(string), {})
  }))
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings for clusters"
  type        = bool
  default     = true
}
