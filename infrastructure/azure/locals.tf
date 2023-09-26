locals {
  default_tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    CostCenter  = "1"
    Application = "ThousandEyes"
    Owner       = "dameda@test.com"
  }

  resource_suffix = "dev-weu-te"
  fw_ip           = "10.20.0.0"
  primary_region  = "westeurope"

  vnets = {
    external = {
      cidr               = "10.1.0.0/16"
      type               = "hub"
      location           = local.primary_region
      peer_to_hub_name   = ""
      peer_to_spoke_name = ""
    },
    app = {
      cidr               = "10.2.0.0/16"
      type               = "spoke"
      location           = local.primary_region
      peer_to_hub_name   = "cn-app-to-external"
      peer_to_spoke_name = "cn-external-to-app"
    },
    db = {
      cidr               = "10.3.0.0/16"
      type               = "spoke"
      location           = local.primary_region
      peer_to_hub_name   = "cn-db-to-external"
      peer_to_spoke_name = "cn-external-to-db"
    }
  }

  subnets = [
    {
      name                       = "mgmt"
      type                       = "public"
      cidr                       = "10.1.10.0/24"
      vnet                       = "external"
      rtb                        = "mgmt"
      nsg                        = "ftd-sg"
      location                   = local.primary_region
      main_rtb                   = false
      delegation_name            = ""
      service_delegation_name    = ""
      service_delegation_actions = ""
      routes = [{
        name        = "mgmt1"
        cidr_dest   = "0.0.0.0/0"
        dest        = "Internet"
        vnet        = "external"
        rtb         = "mgmt"
        next_hop_ip = ""
      }]
    },
    {
      name                       = "outside"
      type                       = "public"
      cidr                       = "10.1.2.0/24"
      vnet                       = "external"
      rtb                        = "outside"
      nsg                        = "ftd-sg"
      location                   = local.primary_region
      main_rtb                   = true
      delegation_name            = ""
      service_delegation_name    = ""
      service_delegation_actions = ""
      routes = [{
        name        = "outside1"
        cidr_dest   = "0.0.0.0/0"
        dest        = "Internet"
        vnet        = "external"
        rtb         = "outside"
        next_hop_ip = ""
      }]
    },
    {
      name                       = "inside"
      type                       = "private"
      cidr                       = "10.1.1.0/24"
      vnet                       = "external"
      rtb                        = "inside"
      nsg                        = "ftd-sg"
      location                   = local.primary_region
      main_rtb                   = false
      delegation_name            = ""
      service_delegation_name    = ""
      service_delegation_actions = ""
      routes = [{
        name        = "inside1"
        cidr_dest   = "0.0.0.0/0"
        dest        = "VirtualAppliance"
        vnet        = "external"
        rtb         = "inside"
        next_hop_ip = local.fw_ip
        },
        {
          name        = "inside2"
          cidr_dest   = "10.2.0.0/16"
          dest        = "VirtualAppliance"
          vnet        = "external"
          rtb         = "inside"
          next_hop_ip = local.fw_ip
        },
        {
          name        = "inside3"
          cidr_dest   = "10.3.0.0/16"
          dest        = "VirtualAppliance"
          vnet        = "external"
          rtb         = "inside"
          next_hop_ip = local.fw_ip
      }]
    },
    {
      name                       = "appnet"
      type                       = "private"
      cidr                       = "10.2.1.0/24"
      vnet                       = "app"
      rtb                        = "appnet"
      nsg                        = "app-sg"
      location                   = local.primary_region
      main_rtb                   = true
      delegation_name            = ""
      service_delegation_name    = ""
      service_delegation_actions = ""
      routes = [{
        name        = "appnet1"
        cidr_dest   = "0.0.0.0/0"
        dest        = "VirtualAppliance"
        vnet        = "app"
        rtb         = "appnet"
        next_hop_ip = local.fw_ip
      }]
    },
    {
      name                       = "dbnet"
      type                       = "private"
      cidr                       = "10.3.1.0/24"
      vnet                       = "db"
      nsg                        = "ftd-http-sg"
      location                   = local.primary_region
      rtb                        = "dbnet"
      main_rtb                   = true
      delegation_name            = "fs"
      service_delegation_name    = "Microsoft.DBforMySQL/flexibleServers"
      service_delegation_actions = "Microsoft.Network/virtualNetworks/subnets/join/action"
      routes = [{
        name        = "dbneta1"
        cidr_dest   = "0.0.0.0/0"
        dest        = "VirtualAppliance"
        vnet        = "dbneta"
        rtb         = "database"
        next_hop_ip = local.fw_ip
      }]
    }
  ]

  nsgs = {
    app-sg = {
      description = "Allow access for app vnet"
      vnet        = "app"
      location    = local.primary_region
      security_rules = {
        http = {
          priority    = 1001
          description = "Allow HTTP"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 80
          protocol    = "Tcp"
          src_cidr    = "*"
          dest_cidr   = "*"

        },
        https = {
          priority    = 1002
          description = "Allow HTTPS"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 443
          protocol    = "Tcp"
          src_cidr    = "*"
          dest_cidr   = "*"
        },
        out = {
          priority    = 1001
          description = "Allow everything"
          access      = "Allow"
          direction   = "Outbound"
          from_port   = "*"
          to_port     = "*"
          protocol    = "*"
          src_cidr    = "*"
          dest_cidr   = "*"
        }
      }
    },
    ftd-http-sg = {
      description = "Allow access for external vnet"
      vnet        = "external"
      location    = local.primary_region
      security_rules = {
        http = {
          priority    = 1001
          description = "Allow HTTP"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 80
          protocol    = "Tcp"
          src_cidr    = "*"
          dest_cidr   = "*"
        },
        https = {
          priority    = 1002
          description = "Allow HTTPS"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 443
          protocol    = "Tcp"
          src_cidr    = "*"
          dest_cidr   = "*"
        },
        mysql = {
          priority    = 1003
          description = "Allow MySQL"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 3306
          protocol    = "Tcp"
          src_cidr    = "10.2.0.0/16"
          dest_cidr   = "*"
        },
        out = {
          priority    = 1001
          description = "Allow everything"
          access      = "Allow"
          direction   = "Outbound"
          from_port   = "*"
          to_port     = "*"
          protocol    = "*"
          src_cidr    = "*"
          dest_cidr   = "*"
        }
      }
    },
    ftd-sg = {
      description = "Allow access for external vnet - ftd"
      vnet        = "external"
      location    = local.primary_region
      security_rules = {
        http = {
          priority    = 1001
          description = "Allow HTTP"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 80
          protocol    = "Tcp"
          src_cidr    = "*"
          dest_cidr   = "*"
        },
        https = {
          priority    = 1002
          description = "Allow HTTPS"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 443
          protocol    = "Tcp"
          src_cidr    = "*"
          dest_cidr   = "*"
        },
        mysql = {
          priority    = 1003
          description = "Allow SSH"
          access      = "Allow"
          direction   = "Inbound"
          from_port   = "*"
          to_port     = 22
          protocol    = "Tcp"
          src_cidr    = "${var.my_ip}/32"
          dest_cidr   = "*"
        },
        out = {
          priority    = 1001
          description = "Allow everything"
          access      = "Allow"
          direction   = "Outbound"
          from_port   = "*"
          to_port     = "*"
          protocol    = "*"
          src_cidr    = "*"
          dest_cidr   = "*"
        }
      }
    }
  }

  pips = {
    mgmt = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      location            = local.primary_region
    },
    outside = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      location            = local.primary_region
    }
  }

  nics = {
    diag = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      location            = local.primary_region
      public_ip           = true
      public_ip_id        = azurerm_public_ip.pip["mgmt"].id
      ip_config_name      = "ip-config-diag"
      subnet_id           = azurerm_subnet.subnet["mgmt"].id
    },
    mgmt = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      location            = local.primary_region
      public_ip           = false
      public_ip_id        = azurerm_public_ip.pip["mgmt"].id
      ip_config_name      = "ip-config-mgmt"
      subnet_id           = azurerm_subnet.subnet["mgmt"].id
    },
    outside = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      location            = local.primary_region
      public_ip           = false
      ip_config_name      = "ip-config-outside"
      subnet_id           = azurerm_subnet.subnet["outside"].id
    },
    inside = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      location            = local.primary_region
      public_ip           = false
      ip_config_name      = "ip-config-inside"
      subnet_id           = azurerm_subnet.subnet["inside"].id
    }
    app = {
      resource_group_name = "rg-app-${local.resource_suffix}"
      location            = local.primary_region
      public_ip           = false
      ip_config_name      = "ip-config-app"
      subnet_id           = azurerm_subnet.subnet["appnet"].id
    }
  }

  vms = {
    ftd = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      location            = local.primary_region
      ip_config_name      = "ip-config-ftd"
      subnet_id           = azurerm_subnet.subnet["mgmt"].id
      nic_ids             = [azurerm_network_interface.nic["diag"].id, azurerm_network_interface.nic["outside"].id]
    },
    app = {
      resource_group_name = "rg-app-${local.resource_suffix}"
      location            = local.primary_region
      subnet_id           = azurerm_subnet.subnet["appnet"].id
      nic_ids             = [azurerm_network_interface.nic["app"].id]
    }
  }
}