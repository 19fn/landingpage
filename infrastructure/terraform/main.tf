locals {
  site_root = "${path.module}/../.."

  custom_domain_is_apex = var.custom_domain_name == var.dns_zone_name
  custom_domain_prefix  = local.custom_domain_is_apex ? "@" : trimsuffix(var.custom_domain_name, ".${var.dns_zone_name}")
  validation_record     = local.custom_domain_is_apex ? "_dnsauth" : "_dnsauth.${local.custom_domain_prefix}"

  root_files = toset([
    "index.html",
    "404.html",
    "styles.css",
    "app.js",
  ])

  badge_files = fileset("${local.site_root}/assets/img", "**")

  public_files = merge(
    { for filename in local.root_files : filename => "${local.site_root}/${filename}" },
    { for filename in local.badge_files : "assets/img/${filename}" => "${local.site_root}/assets/img/${filename}" },
  )

  content_types = {
    ".css"  = "text/css; charset=utf-8"
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
  }
}

data "azurerm_dns_zone" "site" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_resource_group" "site" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = var.tags
}

resource "azurerm_storage_account" "site" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.site.name
  location                 = azurerm_resource_group.site.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_account_static_website" "site" {
  storage_account_id = azurerm_storage_account.site.id

  index_document     = "index.html"
  error_404_document = "404.html"
}

resource "azurerm_storage_blob" "site" {
  for_each = local.public_files

  name                 = each.key
  storage_container_id = "${azurerm_storage_account.site.id}/blobServices/default/containers/$web"
  type                 = "Block"
  source               = each.value
  content_md5          = filemd5(each.value)
  content_type         = lookup(local.content_types, lower(regex("\\.[^.]+$", each.key)), "application/octet-stream")

  depends_on = [azurerm_storage_account_static_website.site]
}

resource "azurerm_cdn_frontdoor_profile" "site" {
  name                = "afd-${var.storage_account_name}"
  resource_group_name = azurerm_resource_group.site.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "site" {
  name                     = "afd-${var.storage_account_name}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.site.id
  enabled                  = true
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "site" {
  name                     = "static-site"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.site.id

  health_probe {
    interval_in_seconds = 120
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "site" {
  name                          = "storage-static-site"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.site.id
  enabled                       = true

  host_name                      = azurerm_storage_account.site.primary_web_host
  origin_host_header             = azurerm_storage_account.site.primary_web_host
  http_port                      = 80
  https_port                     = 443
  certificate_name_check_enabled = true
  priority                       = 1
  weight                         = 1000

  depends_on = [azurerm_storage_account_static_website.site]
}

resource "azurerm_cdn_frontdoor_custom_domain" "site" {
  name                     = "site-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.site.id
  host_name                = var.custom_domain_name

  tls {
    certificate_type = "ManagedCertificate"
    minimum_version  = "TLS12"
  }
}

resource "azurerm_dns_txt_record" "frontdoor_validation" {
  name                = local.validation_record
  zone_name           = data.azurerm_dns_zone.site.name
  resource_group_name = data.azurerm_dns_zone.site.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_cdn_frontdoor_custom_domain.site.validation_token
  }
}

resource "azurerm_dns_cname_record" "frontdoor" {
  count = local.custom_domain_is_apex ? 0 : 1

  name                = local.custom_domain_prefix
  zone_name           = data.azurerm_dns_zone.site.name
  resource_group_name = data.azurerm_dns_zone.site.resource_group_name
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.site.host_name
}

resource "azurerm_dns_a_record" "frontdoor_apex" {
  count = local.custom_domain_is_apex ? 1 : 0

  name                = "@"
  zone_name           = data.azurerm_dns_zone.site.name
  resource_group_name = data.azurerm_dns_zone.site.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.site.id
}

resource "azurerm_cdn_frontdoor_route" "site" {
  name                          = "static-site"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.site.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.site.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.site.id]
  cdn_frontdoor_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.site.id,
  ]

  enabled                = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  depends_on = [
    azurerm_dns_txt_record.frontdoor_validation,
    azurerm_dns_cname_record.frontdoor,
    azurerm_dns_a_record.frontdoor_apex,
  ]
}