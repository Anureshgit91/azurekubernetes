variable "resource_groups" {
  description = "Map of resource groups to create with nested configuration"
  type = map(object({
    location = string
    tags = optional(map(string), {})
    managed_identities = optional(map(object({
      name = string
      type = optional(string, "SystemAssigned")
    })), {})
  }))

  validation {
    condition     = alltrue([for rg in values(var.resource_groups) : contains(["eastus", "westus", "eastus2", "westus2", "centralus", "northeurope", "westeurope"], rg.location)])
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for naming convention"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "create_managed_identities" {
  description = "Whether to create managed identities for resource groups"
  type        = bool
  default     = false
}
