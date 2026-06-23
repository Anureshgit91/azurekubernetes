# =====================================================================
# RESOURCE GROUPS MODULE - Using foreach with nested maps
# =====================================================================

module "resource_groups" {
  source = "../modules/resource_group"

  project_name = var.project_name
  environment  = var.environment

  # Using foreach with nested map structure
  resource_groups = {
    core = {
      location = var.location
      tags = {
        team        = "platform"
        description = "Core infrastructure resources"
      }
      # Nested map for managed identities
      managed_identities = {
        aks_identity = {
          name = "aks"
          type = "SystemAssigned"
        }
        acr_identity = {
          name = "acr"
          type = "SystemAssigned"
        }
      }
    }

    secondary = {
      location = var.secondary_location
      tags = {
        team        = "platform"
        description = "Secondary region resources"
      }
      managed_identities = {
        aks_dr = {
          name = "aks-dr"
        }
      }
    }

    workloads = {
      location = var.location
      tags = {
        team        = "applications"
        description = "Application workloads"
      }
      managed_identities = {}
    }
  }

  create_managed_identities = true

  common_tags = {
    terraform   = "true"
    owner       = "platform-team"
    cost_center = "infrastructure"
  }
}

# =====================================================================
# ACR MODULE - Using foreach with nested maps and conditional logic
# =====================================================================

module "acr" {
  source = "../modules/acr"

  project_name = var.project_name
  environment  = var.environment

  # Using foreach with highly nested configuration
  registries = {
    # Primary production registry with full features
    production = {
      resource_group_name        = module.resource_groups.resource_group_names["core"]
      location                   = var.location
      sku                        = "Premium"
      admin_enabled              = false
      public_network_access_enabled = false

      # Nested network_rules object
      network_rules = {
        default_action = "Deny"
        ip_rules       = concat(var.allowed_ip_ranges, ["203.0.113.0/24"])
        virtual_networks = {
          primary_aks = {
            subnet_id = azurerm_subnet.aks.id
          }
          secondary_aks = {
            subnet_id = azurerm_subnet.acr_endpoints.id
          }
        }
      }

      # Nested encryption configuration
      encryption = {
        enabled            = true
        key_vault_key_id   = azurerm_key_vault.main.id
        identity_client_id = module.resource_groups.managed_identities["core/acr_identity"].id
      }

      # Nested webhooks map
      webhooks = {
        deployment_webhook = {
          service_uri = "https://myapp.example.com/webhooks/acr"
          events      = ["push", "delete"]
          scope       = "*"
          enabled     = true
        }
        notification_webhook = {
          service_uri = "https://notifications.example.com/acr"
          events      = ["push"]
          scope       = "prod/*"
          enabled     = true
        }
      }

      # Nested retention policies
      retention_policies = {
        enabled  = true
        days     = 90
        untagged = true
      }

      tags = {
        tier = "production"
      }
    }

    # Development registry with minimal features
    development = {
      resource_group_name        = module.resource_groups.resource_group_names["workloads"]
      location                   = var.location
      sku                        = "Basic"
      admin_enabled              = true
      public_network_access_enabled = true

      # Minimal network rules for Dev
      network_rules = {
        default_action   = "Allow"
        ip_rules         = []
        virtual_networks = {}
      }

      # No encryption for dev
      encryption = {
        enabled = false
      }

      webhooks = {}

      retention_policies = {
        enabled = false
      }

      tags = {
        tier = "development"
      }
    }

    # Staging registry with conditional features
    staging = {
      resource_group_name        = module.resource_groups.resource_group_names["secondary"]
      location                   = var.secondary_location
      sku                        = "Standard"
      admin_enabled              = false
      public_network_access_enabled = true

      network_rules = {
        default_action   = "Allow"
        ip_rules         = var.allowed_ip_ranges
        virtual_networks = {}
      }

      encryption = {
        enabled = false
      }

      webhooks = {
        staging_webhook = {
          service_uri = "https://staging.example.com/webhooks"
          events      = ["push"]
          scope       = ""
          enabled     = true
        }
      }

      retention_policies = {
        enabled = true
        days    = 30
      }

      tags = {
        tier = "staging"
      }
    }
  }
}

# =====================================================================
# AKS MODULE - Using foreach with comprehensive nested maps and dynamic blocks
# =====================================================================

module "aks" {
  source = "../modules/aks"

  project_name = var.project_name
  environment  = var.environment

  # Using foreach with deeply nested cluster configuration
  clusters = {
    # Production cluster with full configuration
    production = {
      resource_group_name = module.resource_groups.resource_group_names["core"]
      location            = var.location
      kubernetes_version  = null

      # Nested network profile
      network_profile = {
        network_plugin      = "azure"
        network_policy      = "azure"
        service_cidr        = "10.0.0.0/16"
        dns_service_ip      = "10.0.0.10"
        pod_cidr            = null
        docker_bridge_cidr  = null
        outbound_type       = "loadBalancer"
      }

      # Nested default node pool configuration
      default_node_pool = {
        name                = "system"
        vm_size             = "Standard_D2s_v7"
        node_count          = 2
        min_count           = 2
        max_count           = 5
        enable_auto_scaling = true
        availability_zones  = []
        tags = {
          pool_type = "system"
        }
      }

      # Nested map of additional node pools with various configurations
      node_pools = {
        # Compute pool for general workloads
        compute = {
          vm_size             = "Standard_D2s_v7"
          node_count          = 3
          min_count           = 1
          max_count           = 10
          enable_auto_scaling = true
          availability_zones  = []
          labels = {
            workload = "compute"
            tier     = "standard"
          }
          taints = [
            {
              key    = "workload"
              value  = "compute"
              effect = "NoSchedule"
            }
          ]
          tags = {
            pool_type = "compute"
          }
        }

        # GPU pool for ML workloads
        gpu = {
          vm_size             = "Standard_NC6s_v3"
          node_count          = 0
          min_count           = 0
          max_count           = 3
          enable_auto_scaling = true
          availability_zones  = []
          labels = {
            workload = "ml"
            gpu      = "nvidia"
          }
          taints = [
            {
              key    = "nvidia.com/gpu"
              value  = "true"
              effect = "NoSchedule"
            }
          ]
          tags = {
            pool_type = "gpu"
          }
        }

        # Memory-optimized pool for cache/database workloads
        memory_optimized = {
          vm_size             = "Standard_E8s_v3"
          node_count          = 1
          min_count           = 1
          max_count           = 3
          enable_auto_scaling = true
          availability_zones  = []
          labels = {
            workload = "data-processing"
            memory   = "high"
          }
          taints = [
            {
              key    = "workload"
              value  = "data-processing"
              effect = "NoSchedule"
            }
          ]
          tags = {
            pool_type = "memory"
          }
        }

        # Spot instances for cost optimization
        spot = {
          vm_size             = "Standard_D2s_v7"
          node_count          = 2
          min_count           = 0
          max_count           = 5
          enable_auto_scaling = true
          availability_zones  = []
          labels = {
            capacity = "spot"
            cost     = "optimized"
          }
          taints = [
            {
              key    = "capacity"
              value  = "spot"
              effect = "NoSchedule"
            }
          ]
          tags = {
            pool_type = "spot"
          }
        }
      }

      # Nested identity configuration
      identity = {
        type                      = "SystemAssigned"
        user_assigned_identity_id = null
      }

      rbac_enabled = true

      # Nested Azure AD RBAC configuration
      azure_active_directory_role_based_access_control = {
        managed            = true
        tenant_id          = local.current_tenant_id
        admin_group_object_ids = var.admin_group_ids
        azure_rbac_enabled = true
      }

      # Nested add-ons configuration
      addons = {
        http_application_routing_enabled    = false
        ingress_application_gateway_enabled = true
        monitoring_enabled                  = true
        monitoring_log_analytics_workspace_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.main.id
        oms_agent_enabled                   = true
      }

      # Nested auto-scaler profile
      auto_scaler_profile = {
        balance_similar_node_groups      = true
        empty_bulk_delete_max            = 10
        expander                         = "priority"
        max_graceful_termination_sec     = 600
        max_node_provision_time          = "15m"
        max_total_unready_percentage     = 45
        new_pod_scale_down_enabled       = true
        scale_down_delay_after_add       = "10m"
        scale_down_delay_after_failure   = "3m"
        scale_down_delay_after_delete    = "10s"
        scale_down_unneeded              = "10m"
        scale_down_unready               = "20m"
        skip_nodes_with_local_storage    = true
        skip_nodes_with_system_pods      = true
      }

      # Nested maintenance window configuration
      maintenance_window = {
        allowed = [
          {
            day   = "Sunday"
            hours = [2, 3, 4]
          }
        ]
        not_allowed = []
      }

      tags = {
        cluster_tier = "production"
      }
    }

    # Development cluster with simplified configuration
    development = {
      resource_group_name = module.resource_groups.resource_group_names["workloads"]
      location            = var.location
      kubernetes_version  = null

      network_profile = {
        network_plugin      = "azure"
        network_policy      = null
        service_cidr        = "10.0.0.0/16"
        dns_service_ip      = "10.0.0.10"
        pod_cidr            = null
        docker_bridge_cidr  = null
        outbound_type       = "loadBalancer"
      }

      default_node_pool = {
        name                = "default"
        vm_size             = "Standard_D2s_v7"
        node_count          = 1
        min_count           = 1
        max_count           = 3
        enable_auto_scaling = true
        availability_zones  = []
        tags                = {}
      }

      # Minimal additional pools for dev
      node_pools = {
        workload = {
          vm_size             = "Standard_D2s_v7"
          node_count          = 1
          min_count           = 1
          max_count           = 2
          enable_auto_scaling = false
          availability_zones  = []
          labels              = {}
          taints              = []
          tags                = {}
        }
      }

      identity = {
        type                      = "SystemAssigned"
        user_assigned_identity_id = null
      }

      rbac_enabled = true

      azure_active_directory_role_based_access_control = {
        managed            = true
        tenant_id          = local.current_tenant_id
        admin_group_object_ids = var.admin_group_ids
        azure_rbac_enabled = false
      }

      addons = {
        http_application_routing_enabled    = false
        ingress_application_gateway_enabled = false
        monitoring_enabled                  = true
        monitoring_log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
        oms_agent_enabled                   = true
      }

      auto_scaler_profile = {}

      maintenance_window = {
        allowed = []
        not_allowed = []
      }

      tags = {
        cluster_tier = "development"
      }
    }

    # DR cluster in secondary region
    dr = {
      resource_group_name = module.resource_groups.resource_group_names["secondary"]
      location            = var.secondary_location
      kubernetes_version  = null

      network_profile = {
        network_plugin      = "azure"
        network_policy      = "azure"
        service_cidr        = "10.32.0.0/16"
        dns_service_ip      = "10.32.0.10"
        pod_cidr            = null
        docker_bridge_cidr  = null
        outbound_type       = "loadBalancer"
      }

      default_node_pool = {
        name                = "system"
        vm_size             = "Standard_D2s_v7"
        node_count          = 2
        min_count           = 2
        max_count           = 3
        enable_auto_scaling = true
        availability_zones  = []
        tags                = {}
      }

      node_pools = {
        compute = {
          vm_size             = "Standard_D2s_v7"
          node_count          = 1
          min_count           = 1
          max_count           = 3
          enable_auto_scaling = true
          availability_zones  = []
          labels = {
            workload = "compute"
          }
          taints = []
          tags   = {}
        }
      }

      identity = {
        type                      = "SystemAssigned"
        user_assigned_identity_id = null
      }

      rbac_enabled = true

      azure_active_directory_role_based_access_control = {
        managed            = true
        tenant_id          = local.current_tenant_id
        admin_group_object_ids = var.admin_group_ids
        azure_rbac_enabled = true
      }

      addons = {
        http_application_routing_enabled    = false
        ingress_application_gateway_enabled = false
        monitoring_enabled                  = true
        monitoring_log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
        oms_agent_enabled                   = true
      }

      auto_scaler_profile = {
        scale_down_unneeded = "10m"
      }

      maintenance_window = {}

      tags = {
        cluster_tier = "dr"
      }
    }
  }

  enable_diagnostics = true
}
