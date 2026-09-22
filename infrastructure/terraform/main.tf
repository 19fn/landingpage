locals {
  site_root = "${path.module}/../.."

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