# --------------------------------------------------------------------------
# Full Dual-Hub Deployment
# --------------------------------------------------------------------------
# Dual internet/intranet hub VNets with Azure Firewall, NAT Gateway,
# and flow logs.
#
# Resources created:
#   - 1 resource group
#   - 2 NSGs (internet + intranet workload subnets)
#   - 1 NAT gateway (internet hub, using pattern-managed public IP)
#   - 2 VNets (internet 10.0.0.0/16, intranet 10.1.0.0/16)
#   - 5 public IPs (2 FW normal + 2 FW management + 1 NAT GW)
#   - 2 firewall policies (internet + intranet)
#   - 2 firewalls (internet + intranet)
# --------------------------------------------------------------------------

location = "southeastasia"

tags = {
  Environment = "dev"
  Project     = "connectivity-hub"
  ManagedBy   = "terraform"
  Example     = "full-dual-hub"
}

# --------------------------------------------------------------------------
# Resource Groups
# --------------------------------------------------------------------------
resource_groups = {
  rg_connectivity = {
    name = "rg-hub-connectivity-dualhub"
  }
}

# --------------------------------------------------------------------------
# Network Security Groups
# --------------------------------------------------------------------------
network_security_groups = {
  nsg_internet = {
    name               = "nsg-internet-dualhub"
    resource_group_key = "rg_connectivity"
  }
  nsg_intranet = {
    name               = "nsg-intranet-dualhub"
    resource_group_key = "rg_connectivity"
  }
}

# --------------------------------------------------------------------------
# Public IP Addresses (5 total)
# --------------------------------------------------------------------------
public_ips = {
  # Firewall public IPs — internet hub
  pip_fw_internet = {
    name               = "pip-fw-internet-dualhub"
    resource_group_key = "rg_connectivity"
  }
  pip_fw_mgmt_internet = {
    name               = "pip-fw-mgmt-internet-dualhub"
    resource_group_key = "rg_connectivity"
  }
  # Firewall public IPs — intranet hub
  pip_fw_intranet = {
    name               = "pip-fw-intranet-dualhub"
    resource_group_key = "rg_connectivity"
  }
  pip_fw_mgmt_intranet = {
    name               = "pip-fw-mgmt-intranet-dualhub"
    resource_group_key = "rg_connectivity"
  }
  # NAT Gateway public IP
  pip_natgw = {
    name               = "pip-natgw-internet-dualhub"
    resource_group_key = "rg_connectivity"
  }
}

# --------------------------------------------------------------------------
# NAT Gateways (using pattern-managed public IP via key)
# --------------------------------------------------------------------------
nat_gateways = {
  natgw_internet = {
    name               = "natgw-internet-dualhub"
    resource_group_key = "rg_connectivity"
    public_ip_addresses = {
      keys = ["pip_natgw"]
    }
  }
}

# --------------------------------------------------------------------------
# Virtual Networks
# --------------------------------------------------------------------------
virtual_networks = {
  vnet_internet = {
    name               = "vnet-internet-dualhub"
    resource_group_key = "rg_connectivity"
    address_space      = ["10.0.0.0/16"]
    subnets = {
      snet_workload = {
        name             = "snet-workload"
        address_prefixes = ["10.0.1.0/24"]
        network_security_group = {
          key = "nsg_internet"
        }
        nat_gateway = {
          key = "natgw_internet"
        }
      }
      AzureFirewallSubnet = {
        name             = "AzureFirewallSubnet"
        address_prefixes = ["10.0.0.0/26"]
      }
      AzureFirewallManagementSubnet = {
        name             = "AzureFirewallManagementSubnet"
        address_prefixes = ["10.0.0.64/26"]
      }
    }
  }
  vnet_intranet = {
    name               = "vnet-intranet-dualhub"
    resource_group_key = "rg_connectivity"
    address_space      = ["10.1.0.0/16"]
    subnets = {
      snet_workload = {
        name             = "snet-workload"
        address_prefixes = ["10.1.1.0/24"]
        network_security_group = {
          key = "nsg_intranet"
        }
      }
      AzureFirewallSubnet = {
        name             = "AzureFirewallSubnet"
        address_prefixes = ["10.1.0.0/26"]
      }
      AzureFirewallManagementSubnet = {
        name             = "AzureFirewallManagementSubnet"
        address_prefixes = ["10.1.0.64/26"]
      }
    }
  }
}

# --------------------------------------------------------------------------
# Firewall Policies
# --------------------------------------------------------------------------
firewall_policies = {
  fwp_internet = {
    name               = "fwp-internet-dualhub"
    resource_group_key = "rg_connectivity"
    sku                = "Standard"
    dns = {
      proxy_enabled = true
    }
  }
  fwp_intranet = {
    name               = "fwp-intranet-dualhub"
    resource_group_key = "rg_connectivity"
    sku                = "Standard"
  }
}

# --------------------------------------------------------------------------
# Azure Firewalls
# --------------------------------------------------------------------------
firewalls = {
  fw_internet = {
    name               = "fw-internet-dualhub"
    resource_group_key = "rg_connectivity"
    sku_name           = "AZFW_VNet"
    sku_tier           = "Standard"
    firewall_policy = {
      key = "fwp_internet"
    }
    zones = ["1", "2", "3"]
    ip_configuration = {
      default = {
        name = "ipconfig-fw-internet"
        subnet = {
          vnet_key   = "vnet_internet"
          subnet_key = "AzureFirewallSubnet"
        }
        public_ip_address = {
          key = "pip_fw_internet"
        }
      }
    }
    management_ip_configuration = {
      name = "ipconfig-fw-mgmt-internet"
      subnet = {
        vnet_key   = "vnet_internet"
        subnet_key = "AzureFirewallManagementSubnet"
      }
      public_ip_address = {
        key = "pip_fw_mgmt_internet"
      }
    }
  }
  fw_intranet = {
    name               = "fw-intranet-dualhub"
    resource_group_key = "rg_connectivity"
    sku_name           = "AZFW_VNet"
    sku_tier           = "Standard"
    firewall_policy = {
      key = "fwp_intranet"
    }
    zones = ["1", "2", "3"]
    ip_configuration = {
      default = {
        name = "ipconfig-fw-intranet"
        subnet = {
          vnet_key   = "vnet_intranet"
          subnet_key = "AzureFirewallSubnet"
        }
        public_ip_address = {
          key = "pip_fw_intranet"
        }
      }
    }
    management_ip_configuration = {
      name = "ipconfig-fw-mgmt-intranet"
      subnet = {
        vnet_key   = "vnet_intranet"
        subnet_key = "AzureFirewallManagementSubnet"
      }
      public_ip_address = {
        key = "pip_fw_mgmt_intranet"
      }
    }
  }
}

# --------------------------------------------------------------------------
# Flow Log Configuration
# --------------------------------------------------------------------------
# NOTE: Replace the storage_account_id values with a real storage account
# resource ID in your environment.
# flowlog_configuration = {
#   location = "southeastasia"
#   flow_logs = {
#     fl_internet = {
#       enabled            = true
#       name               = "fl-hub-internet"
#       virtual_network = {
#         key = "vnet_internet"
#       }
#       storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-connectivity-dualhub/providers/Microsoft.Storage/storageAccounts/stflowlogsdualhub"
#       retention_policy   = { enabled = true, days = 7 }
#       traffic_analytics = {
#         enabled             = true
#         interval_in_minutes = 10
#       }
#     }
#     fl_intranet = {
#       enabled            = true
#       name               = "fl-hub-intranet"
#       virtual_network = {
#         key = "vnet_intranet"
#       }
#       storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-connectivity-dualhub/providers/Microsoft.Storage/storageAccounts/stflowlogsdualhub"
#       retention_policy   = { enabled = true, days = 7 }
#       traffic_analytics = {
#         enabled             = true
#         interval_in_minutes = 10
#       }
#     }
#   }
# }
