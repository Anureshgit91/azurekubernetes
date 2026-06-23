output "resource_groups" {
  description = "Map of created resource groups"
  value = {
    for rg_name, rg in azurerm_resource_group.rg :
    rg_name => {
      id       = rg.id
      name     = rg.name
      location = rg.location
    }
  }
}

output "resource_group_ids" {
  description = "Map of resource group names to IDs"
  value = {
    for rg_name, rg in azurerm_resource_group.rg :
    rg.name => rg.id
  }
}

output "managed_identities" {
  description = "Map of created managed identities"
  value = {
    for msi_key, msi in azurerm_user_assigned_identity.msi :
    msi_key => {
      id       = msi.id
      name     = msi.name
      client_id = msi.client_id
      principal_id = msi.principal_id
    }
  }
  sensitive = false
}

output "resource_group_names" {
  description = "Map of logical names to actual resource group names"
  value = {
    for rg_name, rg in azurerm_resource_group.rg :
    rg_name => rg.name
  }
}
