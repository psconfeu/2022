resource "azurerm_resource_group" "tfcrescendeodemo-rg" {
  name     = "tfcrescendodemo"
  location = "switzerlandnorth"
}

resource "azurerm_storage_account" "tfcrescendeodemo-sa" {
  name                     = "tfcrescendodemosa11"
  location                 = azurerm_resource_group.tfcrescendeodemo-rg.location
  resource_group_name      = azurerm_resource_group.tfcrescendeodemo-rg.name
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

resource "azurerm_storage_blob" "tfcrescendeodemo-sbindex" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.tfcrescendeodemo-sa.name
  storage_container_name = "$web"
  content_type           = "text/html"
  type                   = "Block"
  source                 = "./www/index.html"
}

resource "azurerm_storage_blob" "tfcrescendeodemo-sb404" {
  name                   = "418.html"
  storage_account_name   = azurerm_storage_account.tfcrescendeodemo-sa.name
  storage_container_name = "$web"
  content_type           = "text/html"
  type                   = "Block"
  source                 = "./www/404.html"
}

resource "azurerm_storage_blob" "tfcrescendeodemo-sbfavicon" {
  name                   = "favicon.png"
  storage_account_name   = azurerm_storage_account.tfcrescendeodemo-sa.name
  storage_container_name = "$web"
  content_type           = "image/png"
  type                   = "Block"
  source                 = "./www/favicon.png"
}

resource "azurerm_storage_blob" "random1" {
  name                   = "random1.png"
  storage_account_name   = azurerm_storage_account.tfcrescendeodemo-sa.name
  storage_container_name = "$web"
  content_type           = "image/png"
  type                   = "Block"
  source                 = "./www/favicon.png"
}

resource "azurerm_storage_blob" "random2" {
  name                   = "random2.png"
  storage_account_name   = azurerm_storage_account.tfcrescendeodemo-sa.name
  storage_container_name = "$web"
  content_type           = "image/png"
  type                   = "Block"
  source                 = "./www/favicon.png"
}

output "storageKey" {
  value     = azurerm_storage_account.tfcrescendeodemo-sa.primary_access_key
  sensitive = true
}
