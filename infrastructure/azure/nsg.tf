resource "azurerm_network_security_group" "nsg" {
  for_each = local.nsgs

  name                = "nsg-${each.key}-${local.resource_suffix}"
  location            = each.value.location
  resource_group_name = "rg-${each.value.vnet}-${local.resource_suffix}"

  dynamic "security_rule" {
    for_each = local.nsgs[each.key].security_rules

    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.from_port
      destination_port_range     = security_rule.value.to_port
      source_address_prefix      = security_rule.value.src_cidr
      destination_address_prefix = security_rule.value.dest_cidr
    }
  }

  tags = merge(local.default_tags, { Name = "nsg-${each.key}-${local.resource_suffix}" })
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = { for subnet, val in local.subnets : val.name => val if val.nsg != "" }

  subnet_id                 = azurerm_subnet.subnet[each.value.name].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg].id
}