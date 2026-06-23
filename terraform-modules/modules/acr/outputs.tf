output "registry_information" {
  description = "Details of created container registries"
  value = {
    for acr_name, acr in azurerm_container_registry.acr :
    acr_name => {
      id                = acr.id
      name              = acr.name
      login_server      = acr.login_server
      admin_username    = acr.admin_username
      admin_password    = acr.admin_password
    }
  }
  sensitive = true
}

output "registry_ids" {
  description = "Map of registry names to their resource IDs"
  value = {
    for acr_name, acr in azurerm_container_registry.acr :
    acr.name => acr.id
  }
}

output "login_servers" {
  description = "Map of registry names to their login servers"
  value = {
    for acr_name, acr in azurerm_container_registry.acr :
    acr_name => acr.login_server
  }
}
