resource "azurerm_public_ip" "pip" {
  for_each = local.pips

  name                = "pip-vm-${each.key}-${local.resource_suffix}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = "Static"

  tags = merge(local.default_tags, { Name = "pip-vm-${each.key}-${local.resource_suffix}" })
}

resource "azurerm_network_interface" "nic" {
  for_each = local.nics

  name                = "nic-${each.key}-${local.resource_suffix}"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  ip_configuration {
    name                          = each.value.ip_config_name
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.public_ip == true ? each.value.public_ip_id : null
    subnet_id                     = each.value.subnet_id
  }

  tags = merge(local.default_tags, { Name = "nic-${each.key}-${local.resource_suffix}" })
}