# -----------------------------------------------------------------------------
# main.tf - resource group + storage account foundation.
# -----------------------------------------------------------------------------

locals {
  # Merge the environment into the tag set so every resource carries it.
  common_tags = merge(var.tags, { environment = var.environment })
}

# Storage account names must be globally unique, 3-24 chars, lowercase letters
# and numbers only. A random 5-character suffix avoids name collisions.
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "foundation" {
  name     = "rg-${var.workload}-tf-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "foundation" {
  name                     = "st${var.workload}${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.foundation.name
  location                 = azurerm_resource_group.foundation.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # cheapest redundancy - fine for a lab
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  # Basic security baseline
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = local.common_tags
}
