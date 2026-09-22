output "resource_group_id" {
  description = "ID of the resource group created for the landing page."
  value       = azurerm_resource_group.site.id
}

output "storage_account_id" {
  description = "ID of the static website storage account."
  value       = azurerm_storage_account.site.id
}

output "storage_account_name" {
  description = "Name of the static website storage account."
  value       = azurerm_storage_account.site.name
}

output "website_url" {
  description = "Primary Azure Storage Static Website endpoint."
  value       = azurerm_storage_account.site.primary_web_endpoint
}