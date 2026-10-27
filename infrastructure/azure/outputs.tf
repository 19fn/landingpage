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

output "frontdoor_endpoint_url" {
  description = "Default Azure Front Door endpoint."
  value       = "https://${azurerm_cdn_frontdoor_endpoint.site.host_name}"
}

output "custom_domain_url" {
  description = "Custom HTTPS URL served through Azure Front Door."
  value       = "https://${var.custom_domain_name}"
}

output "custom_domain_dns_record" {
  description = "Azure DNS record used to route the custom domain to Front Door."
  value = local.custom_domain_is_apex ? {
    type   = "A (alias)"
    name   = "@"
    target = azurerm_cdn_frontdoor_endpoint.site.id
    } : {
    type   = "CNAME"
    name   = local.custom_domain_prefix
    target = azurerm_cdn_frontdoor_endpoint.site.host_name
  }
}

output "custom_domain_validation_record" {
  description = "TXT record used by Front Door to validate the custom hostname."
  value = {
    name  = local.validation_record
    value = azurerm_cdn_frontdoor_custom_domain.site.validation_token
  }
}