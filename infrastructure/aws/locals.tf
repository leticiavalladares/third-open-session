locals {
  default_tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    CostCenter  = "1"
    Application = "ThousandEyes"
    Owner       = "dameda@test.com"
  }

  resource_suffix = "dev-weu-te"
  rtb_name_prefix = "rtb-${local.resource_suffix}"
  tgw_att_prefix  = "tg-to"
  aws_account_id  = data.aws_caller_identity.current_account.account_id
  primary_region  = "eu-central-1a"

  vpcs = {
    external = {
      cidr           = "10.1.0.0/16",
      type           = "hub",
      tgw_attachment = "inside"
    },
    app = {
      cidr           = "10.2.0.0/16",
      type           = "spoke",
      tgw_attachment = "appnet"
    },
    db = {
      cidr           = "10.3.0.0/16",
      type           = "spoke",
      tgw_attachment = "dbneta"
    }
  }

  subnets = [
    {
      name     = "mgmt"
      type     = "public"
      cidr     = "10.1.10.0/24"
      vpc      = "external"
      rtb      = "mgmt"
      main_rtb = false
      az       = local.primary_region
      routes = [{
        name      = "mgmt1"
        cidr_dest = "0.0.0.0/0"
        dest      = "igw"
        vpc       = "external"
        rtb       = "mgmt"
      }]
    },
    {
      name     = "outside"
      type     = "public"
      cidr     = "10.1.2.0/24"
      vpc      = "external"
      rtb      = "outside"
      main_rtb = true
      az       = local.primary_region
      routes = [{
        name      = "outside1"
        cidr_dest = "0.0.0.0/0"
        dest      = "igw"
        vpc       = "external"
        rtb       = "outside"
      }]

    },
    {
      name     = "inside"
      type     = "private"
      cidr     = "10.1.1.0/24"
      vpc      = "external"
      rtb      = "inside"
      main_rtb = false
      az       = local.primary_region
      routes = [{
        name      = "inside1"
        cidr_dest = "0.0.0.0/0"
        dest      = "nat"
        vpc       = "external"
        rtb       = "inside"
        },
        {
          name      = "inside2"
          cidr_dest = "10.2.0.0/16"
          dest      = "tgw"
          vpc       = "external"
          rtb       = "inside"
        },
        {
          name      = "inside3"
          cidr_dest = "10.3.0.0/16"
          dest      = "tgw"
          vpc       = "external"
          rtb       = "inside"
      }]
    },
    {
      name     = "appnet"
      type     = "private"
      cidr     = "10.2.1.0/24"
      vpc      = "app"
      rtb      = "app"
      main_rtb = true
      az       = local.primary_region
      routes = [{
        name      = "appnet1"
        cidr_dest = "0.0.0.0/0"
        dest      = "tgw"
        vpc       = "app"
        rtb       = "app"
      }]
    },
    {
      name     = "dbneta"
      type     = "private"
      cidr     = "10.3.1.0/24"
      vpc      = "db"
      rtb      = "databasea"
      main_rtb = true
      az       = local.primary_region
      routes = [{
        name      = "dbneta1"
        cidr_dest = "0.0.0.0/0"
        dest      = "tgw"
        vpc       = "db"
        rtb       = "database"
      }]
    },
    {
      name     = "dbnetb"
      type     = "private"
      cidr     = "10.3.2.0/24"
      vpc      = "db"
      rtb      = "databaseb"
      main_rtb = false
      az       = "eu-central-1b"
      routes = [{
        name      = "dbneta2"
        cidr_dest = "0.0.0.0/0"
        dest      = "tgw"
        vpc       = "db"
        rtb       = "database"
      }]
    }
  ]

  sg = {
    app-sg = {
      description = "Allow access for app vpc"
      vpc         = "app"
      inbound_rules = {
        http = {
          description = "Allow HTTP"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        },
        https = {
          description = "Allow HTTPS"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        }
      }
    },
    ftd-http-sg = {
      description = "Allow access for external vpc"
      vpc         = "external"
      inbound_rules = {
        http = {
          description = "Allow HTTP"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        },
        https = {
          description = "Allow HTTPS"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        },
        mysql = {
          description = "Allow MySQL/Aurora"
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          cidr_block  = "10.2.0.0/16"
        }
      }
    },
    ftd-sg = {
      description = "Allow access for external vpc - ftd"
      vpc         = "external"
      inbound_rules = {
        http = {
          description = "Allow HTTP"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        },
        https = {
          description = "Allow HTTPS"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        },
        mysql = {
          description = "Allow SSH"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "${var.my_ip}/32"
        }
      }
    }
  }

  enis = {    
    diag = {
      private_ip     = "10.1.10.11"
      public_ip      = true
      subnet         = "mgmt"
      sg             = "ftd-http-sg"
      src_dest_check = true
    },
    inside = {
      private_ip     = "10.1.1.10"
      public_ip      = false
      subnet         = "inside"
      sg             = "ftd-http-sg"
      src_dest_check = true
    },
    outside = {
      private_ip     = "10.1.2.10"
      public_ip      = true
      subnet         = "outside"
      sg             = "ftd-http-sg"
      src_dest_check = false
    }
  }

  ec2 = {
    ftd = {
      resource_group_name = "rg-external-${local.resource_suffix}"
      ami                 = data.aws_ami.aws_basic_linux.id
      location            = local.primary_region
      ip_config_name      = "ip-config-ftd"
      instance_type       = "t3.medium"
      sg                  = "ftd-http-sg"
      subnet_id           = aws_subnet.subnet["mgmt"].id
    },
    app = {
      resource_group_name = "rg-app-${local.resource_suffix}"
      ami                 = data.aws_ami.aws_basic_linux.id
      location            = local.primary_region
      instance_type       = "t3.medium"
      sg                  = "app-sg"
      subnet_id           = aws_subnet.subnet["appnet"].id
    }
  }

  tgw_rtb_name_tags = [
    "${local.tgw_att_prefix}-app",
    "${local.tgw_att_prefix}-db",
    "${local.tgw_att_prefix}-external"
  ]
}