locals {
  # Merge common tags with resource group specific tags
  merged_tags = {
    for rg_name, rg_config in var.resource_groups :
    rg_name => merge(
      var.common_tags,
      {
        environment = var.environment
        project     = var.project_name
      },
      rg_config.tags
    )
  }
}

# Create Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups

  name       = format("%s-%s-%s-rg", var.project_name, each.key, var.environment)
  location   = each.value.location
  tags       = local.merged_tags[each.key]

  lifecycle {
    ignore_changes = [tags["last_modified"]]
  }
}

# Create User-Assigned Managed Identities
resource "azurerm_user_assigned_identity" "msi" {
  for_each = var.create_managed_identities ? merge([
    for rg_name, rg_config in var.resource_groups : {
      for msi_name, msi_config in rg_config.managed_identities :
      "${rg_name}/${msi_name}" => {
        rg_name     = rg_name
        msi_name    = msi_name
        msi_config  = msi_config
      }
    }
  ]...) : {}

  name                = format("%s-%s-%s-msi", var.project_name, each.value.msi_name, var.environment)
  resource_group_name = azurerm_resource_group.rg[each.value.rg_name].name
  location            = azurerm_resource_group.rg[each.value.rg_name].location
  tags                = local.merged_tags[each.value.rg_name]
}
