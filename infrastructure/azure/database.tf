resource "azurerm_mysql_flexible_server" "mysql_flexible_server" {
  name                   = "fs-db-${local.resource_suffix}"
  resource_group_name    = "rg-db-${local.resource_suffix}"
  location               = local.primary_region
  administrator_login    = data.azurerm_key_vault_secret.secret_db_user.value
  administrator_password = data.azurerm_key_vault_secret.secret_db_pwd.value
  backup_retention_days  = 7
  # delegated_subnet_id    = azurerm_subnet.subnet["db"].id
  sku_name               = "GP_Standard_D2ds_v4"
  zone                   = 3
}