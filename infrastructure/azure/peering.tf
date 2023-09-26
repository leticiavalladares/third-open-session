resource "azurerm_virtual_network_peering" "vnet_peering_to_hub" {
  for_each = { for vnet, val in local.vnets : vnet => val if val.type != "hub" }

  name                         = each.value.peer_to_hub_name
  resource_group_name          = "rg-${each.key}-${local.resource_suffix}"
  virtual_network_name         = azurerm_virtual_network.vnet[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[element(keys({ for n, val in local.vnets : n => val if val.type == "hub" }), 0)].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_virtual_network_peering" "vnet_peering_to_spoke" {
  for_each = { for vnet, val in local.vnets : vnet => val if val.type != "hub" }

  name                         = each.value.peer_to_spoke_name
  resource_group_name          = "rg-${element(keys({ for n, val in local.vnets : n => val if val.type == "hub" }), 0)}-${local.resource_suffix}"
  virtual_network_name         = azurerm_virtual_network.vnet[element(keys({ for n, val in local.vnets : n => val if val.type == "hub" }), 0)].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_route_table" "route_table" {
  for_each = { for subnet, val in local.subnets : val.rtb => val if val.rtb != "" }

  name                          = "rtb-${each.key}-${local.resource_suffix}"
  location                      = each.value.location
  resource_group_name           = "rg-${each.value.vnet}-${local.resource_suffix}"
  disable_bgp_route_propagation = false

  dynamic "route" {
    for_each = { for route, val in flatten([for sub, v in local.subnets.*.routes :
      [for n in local.subnets.*.routes[sub] : {
        name        = n.name
        dest        = n.dest
        rtb         = n.rtb
        cidr_dest   = n.cidr_dest
        next_hop_ip = n.next_hop_ip
    } if n.rtb == each.value.rtb]]) : route => val }

    content {
      name                   = "route-${route.value.name}-to-${lower(route.value.dest)}"
      address_prefix         = route.value.cidr_dest
      next_hop_type          = route.value.dest
      next_hop_in_ip_address = route.value.next_hop_ip != "" ? route.value.next_hop_ip : null
    }
  }
}

resource "azurerm_subnet_route_table_association" "route_table_assoc" {
  for_each = { for subnet, val in local.subnets : val.name => val if val.rtb != "" }

  subnet_id      = azurerm_subnet.subnet[each.value.name].id
  route_table_id = azurerm_route_table.route_table[each.value.name].id
}