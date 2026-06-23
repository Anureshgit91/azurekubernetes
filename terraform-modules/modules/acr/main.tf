locals {
  merged_tags = {
    for acr_name, acr_config in var.registries :
    acr_name => merge(
      var.common_tags,
      {
        environment = var.environment
        project     = var.project_name
        module      = "acr"
      },
      acr_config.tags
    )
  }
}

# Create Container Registries
resource "azurerm_container_registry" "acr" {
  for_each = var.registries

  name                = replace(format("%s%s%s", var.project_name, each.key, var.environment), "-", "")
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku

  admin_enabled                = each.value.admin_enabled
  public_network_access_enabled = each.value.sku == "Premium" ? each.value.public_network_access_enabled : true

  tags = local.merged_tags[each.key]

  lifecycle {
    ignore_changes = [tags["last_modified"]]
  }
}

# Note: Network rules and encryption are configured at registry level in newer Azure provider

# Note: Webhooks and retention policies managed through registry configuration or Azure portal
