# Create Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = format("%s-%s-law", var.project_name, var.environment)
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.environment
    project     = var.project_name
    module      = "monitoring"
  }
}

# Create Storage Account for diagnostic logs
resource "azurerm_storage_account" "diagnostics" {
  name                     = format("%sdiag%s", var.project_name, var.environment)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

locals {
  key_vault_name_project = substr(replace(lower(var.project_name), "_", ""), 0, 8)
  key_vault_name_env     = substr(replace(lower(var.environment), "_", ""), 0, 4)
  key_vault_name_suffix  = substr(md5(local.current_subscription_id), 0, 4)
  key_vault_name         = format("%s-%s-kv-%s", local.key_vault_name_project, local.key_vault_name_env, local.key_vault_name_suffix)
}

# Create Key Vault for secrets management
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = local.current_tenant_id
  sku_name            = "premium"

  enable_rbac_authorization = true
  purge_protection_enabled  = true
  soft_delete_retention_days = 7

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = format("%s-%s-vnet", var.project_name, var.environment)
  address_space       = ["10.0.0.0/8"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create Subnets
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "acr_endpoints" {
  name                 = "acr-endpoints-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.2.0.0/24"]
}

# Create temporary resource group for prerequisites
resource "azurerm_resource_group" "main" {
  name     = format("%s-%s-rg-main", var.project_name, var.environment)
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}
