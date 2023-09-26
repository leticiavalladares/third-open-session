data "azurerm_key_vault" "existing_key_vault" {
  name                = "examplekeyvault0923"
  resource_group_name = "rg-acr"
}

data "azurerm_key_vault_secret" "secret_vm_user" {
  name         = "vm-user"
  key_vault_id = data.azurerm_key_vault.existing_key_vault.id
}

data "azurerm_key_vault_secret" "secret_vm_pwd" {
  name         = "vm-pwd"
  key_vault_id = data.azurerm_key_vault.existing_key_vault.id
}

data "azurerm_key_vault_secret" "secret_db_user" {
  name         = "mysql-user"
  key_vault_id = data.azurerm_key_vault.existing_key_vault.id
}

data "azurerm_key_vault_secret" "secret_db_pwd" {
  name         = "mysql-pwd"
  key_vault_id = data.azurerm_key_vault.existing_key_vault.id
}