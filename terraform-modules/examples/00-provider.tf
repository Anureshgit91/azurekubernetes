terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
  
  skip_provider_registration = false
}

# Data source for current subscription and tenant
data "azurerm_client_config" "current" {}

locals {
  current_subscription_id = data.azurerm_client_config.current.subscription_id
  current_tenant_id       = data.azurerm_client_config.current.tenant_id
}
