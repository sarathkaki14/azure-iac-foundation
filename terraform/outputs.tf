# -----------------------------------------------------------------------------
# outputs.tf - values printed after apply (and stored in state).
# -----------------------------------------------------------------------------
output "resource_group_name" {
  description = "Name of the resource group created by Terraform."
  value       = azurerm_resource_group.foundation.name
}

output "storage_account_name" {
  description = "Name of the storage account created by Terraform."
  value       = azurerm_storage_account.foundation.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.foundation.id
}

output "primary_blob_endpoint" {
  description = "Blob service endpoint of the storage account."
  value       = azurerm_storage_account.foundation.primary_blob_endpoint
}
