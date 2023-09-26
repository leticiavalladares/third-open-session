resource "aws_internet_gateway" "ig_external_vpc" {
  vpc_id = aws_vpc.vpc["external"].id

  tags = { Name = "igw-${local.resource_suffix}" }
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_external_vpc" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet["inside"].id

  tags = { Name = "appnat-${local.resource_suffix}" }

  depends_on = [aws_internet_gateway.ig_external_vpc]
}

resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "tgw-${local.resource_suffix}"
  auto_accept_shared_attachments  = "enable"
  dns_support                     = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = { Name = "tgw-${local.resource_suffix}" }
}

resource "aws_ec2_transit_gateway_route_table" "tgw_rtb" {
  for_each = toset(local.tgw_rtb_name_tags)

  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = { Name = each.key }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_att" {
  for_each = local.vpcs

  subnet_ids = [
    each.key == "external" ? aws_subnet.subnet[each.value.tgw_attachment].id :
    each.key == "db" ? aws_subnet.subnet[each.value.tgw_attachment].id : aws_subnet.subnet[each.value.tgw_attachment].id
  ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc[each.key].id
}
