# Minimal Single-Hub Deployment
# This example deploys a single hub VNet with one NSG.

location = "southeastasia"

tags = {
  Environment = "dev"
  Project     = "connectivity-hub"
  ManagedBy   = "terraform"
  Example     = "default"
}

resource_groups = {
  rg_hub = {
    name = "rg-hub-connectivity-def"
  }
}

network_security_groups = {
  nsg_default = {
    name               = "nsg-default-def"
    resource_group_key = "rg_hub"
  }
}

virtual_networks = {
  vnet_hub = {
    name               = "vnet-hub-def"
    resource_group_key = "rg_hub"
    address_space      = ["10.0.0.0/16"]
    subnets = {
      snet_default = {
        name                       = "snet-default"
        address_prefixes           = ["10.0.1.0/24"]
        network_security_group_key = "nsg_default"
      }
    }
  }
}
