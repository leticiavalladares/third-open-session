resource "aws_vpc" "vpc" {
  for_each = local.vpcs

  cidr_block       = each.value.cidr
  instance_tenancy = "default"

  tags = {
    Name = "vpc-${each.key}-${local.resource_suffix}"
  }
}

resource "aws_subnet" "subnet" {
  for_each = { for subnet, val in local.subnets : val.name => val }

  vpc_id            = aws_vpc.vpc[each.value.vpc].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = { Name = "subnet-${each.value.name}-${local.resource_suffix}" }
}

resource "aws_route_table" "rtb" {
  for_each = { for subnet, val in local.subnets : val.rtb => val if val.rtb != "" }

  vpc_id = aws_vpc.vpc[each.value.vpc].id

  dynamic "route" {
    for_each = { for route in flatten([for sub, v in local.subnets.*.routes :
      [for n in local.subnets.*.routes[sub] : {
        name      = n.name
        dest      = n.dest
        rtb       = n.rtb
        cidr_dest = n.cidr_dest
    } if n.rtb == each.value.rtb && n.dest == "igw"]]) : route.name => route }

    content {
      cidr_block = route.value.cidr_dest
      gateway_id = aws_internet_gateway.ig_external_vpc.id
    }
  }

  dynamic "route" {
    for_each = { for route, val in flatten([for sub, v in local.subnets.*.routes :
      [for n in local.subnets.*.routes[sub] : {
        name      = n.name
        dest      = n.dest
        rtb       = n.rtb
        cidr_dest = n.cidr_dest
    } if n.rtb == each.value.rtb && n.dest == "nat"]]) : route => val }

    content {
      cidr_block     = route.value.cidr_dest
      nat_gateway_id = aws_nat_gateway.nat_external_vpc.id
    }
  }

  dynamic "route" {
    for_each = { for route, val in flatten([for sub, v in local.subnets.*.routes :
      [for n in local.subnets.*.routes[sub] : {
        name      = n.name
        dest      = n.dest
        rtb       = n.rtb
        cidr_dest = n.cidr_dest
    } if n.rtb == each.value.rtb && n.dest == "tgw"]]) : route => val }

    content {
      cidr_block         = route.value.cidr_dest
      transit_gateway_id = aws_ec2_transit_gateway.tgw.id
    }
  }

  tags = { Name = "rtb-${each.key}-subnet" }

  depends_on = [aws_vpc.vpc, aws_ec2_transit_gateway.tgw]
}

resource "aws_main_route_table_association" "main_rtb_assoc" {
  for_each = { for subnet, val in local.subnets : val.rtb => val if val.main_rtb == true }

  vpc_id         = aws_vpc.vpc[each.value.vpc].id
  route_table_id = aws_route_table.rtb[each.value.rtb].id
}

resource "aws_route_table_association" "rtb_assoc" {
  for_each = { for subnet, val in local.subnets : val.rtb => val if val.main_rtb == false }

  subnet_id      = aws_subnet.subnet[each.value.name].id
  route_table_id = aws_route_table.rtb[each.value.rtb].id
}

resource "aws_db_subnet_group" "db_sg" {
  name        = "db-subnet-group"
  description = "Subnets where RDS will be deployed"
  subnet_ids = [
    aws_subnet.subnet["dbneta"].id,
    aws_subnet.subnet["dbnetb"].id
  ]

  tags = { Name = "db-snet-group" }
}