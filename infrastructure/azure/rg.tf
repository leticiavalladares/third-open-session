resource "azurerm_resource_group" "resource_group" {
  for_each = local.vnets

  name     = "rg-${each.key}-${local.resource_suffix}"
  location = each.value.location

  tags = merge(local.default_tags, { Name = "rg-${each.key}-${local.resource_suffix}" })
}