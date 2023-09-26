resource "aws_network_interface" "eni" {
  for_each = local.enis

  subnet_id         = aws_subnet.subnet[each.value.subnet].id
  private_ips       = [each.value.private_ip]
  security_groups   = [each.value.sg != "" ? aws_security_group.sg[each.value.sg].id : ""]
  source_dest_check = each.value.src_dest_check

  tags = { Name = "eni-${each.key}-${local.resource_suffix}" }
}

resource "aws_eip" "eni_eip" {
  for_each = { for eni, val in local.enis : eni => val if val.public_ip == true }

  vpc = true
}

resource "aws_eip_association" "eni_eip_assoc" {
  for_each = { for eni, val in local.enis : eni => val if val.public_ip == true }

  allocation_id        = aws_eip.eni_eip[each.key].id
  network_interface_id = aws_network_interface.eni[each.key].id
}