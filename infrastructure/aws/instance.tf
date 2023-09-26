resource "aws_instance" "app_instance" {
  for_each = local.ec2

  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [aws_security_group.sg[each.value.sg].id]
  key_name               = "talent-academy-myec2"

  tags = { Name = "ec2-${each.key}-${local.resource_suffix}" }
}