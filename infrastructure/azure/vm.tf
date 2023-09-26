resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.vms

  name                = "vm-${each.key}-${local.resource_suffix}"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  size                = "Standard_A2_v2"

  disable_password_authentication = false

  network_interface_ids = each.value.nic_ids

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "os-vm-${each.key}-${local.resource_suffix}"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = data.azurerm_key_vault_secret.secret_vm_user.value
  admin_password = data.azurerm_key_vault_secret.secret_vm_pwd.value

  tags = merge(local.default_tags, { Name = "vm-${each.key}-${local.resource_suffix}" })
}
