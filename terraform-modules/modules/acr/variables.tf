variable "registries" {
  description = "Map of container registries to create with nested configuration"
  type = map(object({
    resource_group_name = string
    location            = string
    sku                 = optional(string, "Basic")
    
    # Optional ACR configurations
    admin_enabled                = optional(bool, false)
    public_network_access_enabled = optional(bool, false)
    
    # Network rules
    network_rules = optional(object({
      default_action = optional(string, "Allow")
      ip_rules       = optional(list(string), [])
      virtual_networks = optional(map(object({
        subnet_id = string
      })), {})
    }), {})
    
    # Encryption with CMK
    encryption = optional(object({
      enabled            = optional(bool, false)
      key_vault_key_id   = optional(string)
      identity_client_id = optional(string)
    }), {})
    
    # Webhooks configuration
    webhooks = optional(map(object({
      service_uri = string
      events      = list(string)
      scope       = optional(string, "")
      enabled     = optional(bool, true)
    })), {})
    
    # Retention policies
    retention_policies = optional(object({
      enabled      = optional(bool, false)
      days         = optional(number, 30)
      untagged     = optional(bool, false)
    }), {})
    
    tags = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for acr in values(var.registries) : contains(["Basic", "Standard", "Premium"], acr.sku)])
    error_message = "SKU must be Basic, Standard, or Premium."
  }

  validation {
    condition = alltrue([for acr in values(var.registries) : acr.sku == "Premium" || acr.public_network_access_enabled == true])
    error_message = "public_network_access_enabled can only be false for Premium SKU container registries."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for naming"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "create_private_endpoint" {
  description = "Whether to create private endpoints for registries"
  type        = bool
  default     = false
}
