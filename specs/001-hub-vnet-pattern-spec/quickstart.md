# Quickstart: PLZ Connectivity Hub VNet Pattern

**Date**: 2026-03-30 | **Branch**: `001-hub-vnet-pattern-spec`

---

## Resource Module Decomposition Amendment

**Date**: 2026-04-09

The pattern now uses individual AVM resource modules instead of the monolithic core AVM pattern module. The consumer-facing variable interface has changed from a single `hub_virtual_networks` map to individual flat global map variables per resource type.

### Updated Minimal Deployment

```hcl
location         = "southeastasia"
enable_telemetry = false

tags = {
  environment = "production"
  managed_by  = "terraform"
  pattern     = "plz-connectivity-hub-vnet"
}

resource_groups = {
  rg_connectivity = {
    name = "rg-connectivity-hub-sea"
  }
}

virtual_networks = {
  vnet_hub = {
    name               = "vnet-hub-sea"
    resource_group_key = "rg_connectivity"
    address_space      = ["10.0.0.0/16"]
    subnets = {
      snet_default = {
        name                      = "snet-default"
        address_prefixes          = ["10.0.1.0/24"]
        network_security_group_key = "nsg_default"
      }
      AzureFirewallSubnet = {
        name             = "AzureFirewallSubnet"
        address_prefixes = ["10.0.0.0/26"]
      }
    }
  }
}

network_security_groups = {
  nsg_default = {
    name               = "nsg-default-sea"
    resource_group_key = "rg_connectivity"
    security_rules = {
      allow_https_inbound = {
        name                       = "AllowHTTPSInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
    }
  }
}

firewalls = {
  fw_hub = {
    name               = "fw-hub-sea"
    resource_group_key = "rg_connectivity"
    sku_name           = "AZFW_VNet"
    sku_tier           = "Standard"
    # ... additional firewall parameters
  }
}

firewall_policies = {
  fwp_hub = {
    name               = "fwp-hub-sea"
    resource_group_key = "rg_connectivity"
    sku                = "Standard"
    dns = {
      proxy_enabled = true
    }
  }
}
```

> **Note**: The previous quickstart content below is preserved for historical context. The variable interface has changed — use the updated example above.

---

## Simplification Amendment

**Date**: 2026-03-30

The pattern has been simplified. The following capabilities are no longer managed by this pattern:
- Log Analytics Workspace (consumers provide LAW IDs via `diagnostic_settings` directly)
- Storage accounts (flow logs take `storage_account_id` directly)
- Hub-to-spoke VNet peering (handled by core pattern)
- Route tables, private DNS zones, managed identities, role assignments (all handled by core pattern or out of scope)

The quickstart examples below are preserved for historical context. Adjust usage to match the simplified variable interface (see `contracts/variable-interface.md`).

---

## Prerequisites

- Terraform `>= 1.13, < 2.0`
- Azure CLI authenticated to the target subscription
- Network Contributor (or equivalent) RBAC on the target subscription
- If peering to spoke VNets: Network Contributor on spoke subscriptions

---

## Minimal Deployment

> **Passthrough principle**: Every AVM module parameter is exposed via root-level variables. Consumers configure everything through `terraform.tfvars` — never by editing module source code.

### 1. Create `terraform.tfvars`

```hcl
location         = "southeastasia"
enable_telemetry = true

tags = {
  environment = "production"
  managed_by  = "terraform"
  pattern     = "plz-connectivity-hub-vnet"
}

resource_groups = {
  rg_connectivity = {
    name = "rg-connectivity-hub-sea"
  }
}

hub_virtual_networks = {
  hub_sea = {
    location = "southeastasia"

    hub_virtual_network = {
      address_space = ["10.0.0.0/16"]
      subnets = {
        snet_default = {
          name             = "snet-default"
          address_prefixes = ["10.0.1.0/24"]
          network_security_group = {
            id = null  # Will be resolved from nsg_key — see wrapper docs
          }
        }
      }
    }

    firewall = {
      sku_tier              = "Standard"
      subnet_address_prefix = "10.0.0.0/26"
      zones                 = ["1", "2", "3"]
    }

    firewall_policy = {
      sku = "Standard"
      dns = {
        proxy_enabled = true
      }
    }

    bastion = {
      subnet_address_prefix = "10.0.0.64/26"
      sku                   = "Standard"
      tunneling_enabled     = true
    }

    enabled_resources = {
      firewall                              = true
      bastion                               = true
      virtual_network_gateway_vpn           = false
      virtual_network_gateway_express_route = false
      private_dns_zones                     = true
      private_dns_resolver                  = false
    }
  }
}

network_security_groups = {
  nsg_default = {
    name               = "nsg-default-sea"
    resource_group_key = "rg_connectivity"
    security_rules = {
      allow_https_inbound = {
        name                       = "AllowHTTPSInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
      }
    }
  }
}

log_analytics_workspace_configuration = {
  name               = "law-connectivity-hub-sea"
  resource_group_key = "rg_connectivity"
  retention_in_days  = 30
}
```

### 2. Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Verify

```bash
# Check outputs
terraform output hub_virtual_network_ids
terraform output firewall_private_ip_addresses

# Verify idempotency
terraform plan  # Should show "No changes"
```

---

## Adding Hub-to-Spoke Peering

```hcl
# In terraform.tfvars — add spoke peering entries
spoke_virtual_networks = {
  spoke_app1 = {
    spoke_vnet_resource_id = "/subscriptions/.../resourceGroups/rg-spoke-app1/providers/Microsoft.Network/virtualNetworks/vnet-spoke-app1"
    hub_key                = "hub_sea"
  }
  spoke_app2 = {
    spoke_vnet_resource_id = "/subscriptions/.../resourceGroups/rg-spoke-app2/providers/Microsoft.Network/virtualNetworks/vnet-spoke-app2"
    hub_key                = "hub_sea"
  }
}
```

---

## Adding Flow Logs

```hcl
# Storage for flow logs
storage_accounts = {
  sa_flowlogs = {
    name                   = "stflowlogssea001"
    resource_group_key     = "rg_connectivity"
    account_replication_type = "ZRS"
  }
}

# Flow log configuration
flowlog_configuration = {
  flow_logs = {
    fl_hub_sea = {
      enabled  = true
      name     = "fl-hub-sea"
      vnet_key = "hub_sea"
      retention_policy = {
        days    = 30
        enabled = true
      }
      storage_account = {
        key = "sa_flowlogs"
      }
      traffic_analytics = {
        enabled             = true
        interval_in_minutes = 10
      }
    }
  }
}
```

---

## Using BYO Log Analytics Workspace

```hcl
# Instead of log_analytics_workspace_configuration, use:
byo_log_analytics_workspace = {
  resource_id = "/subscriptions/.../resourceGroups/rg-shared/providers/Microsoft.OperationalInsights/workspaces/law-central"
}
# Do NOT set log_analytics_workspace_configuration when using BYO
```

---

## Dual-Hub Deployment (Internet + Intranet)

```hcl
hub_virtual_networks = {
  hub_internet = {
    location = "southeastasia"
    hub_virtual_network = {
      address_space = ["10.0.0.0/16"]  # GEN Non Routable
      # ...
    }
    firewall = {
      sku_tier              = "Standard"
      subnet_address_prefix = "10.0.0.0/26"
    }
    # NAT Gateway + Bastion enabled
  }
  hub_intranet = {
    location = "southeastasia"
    hub_virtual_network = {
      address_space = ["10.1.0.0/16"]  # GEN Routable
      # ...
    }
    firewall = {
      sku_tier              = "Standard"
      subnet_address_prefix = "10.1.0.0/26"
    }
    # Firewall only — no NAT Gateway, no Bastion
  }
}

# Common Services VNet peered to both hubs (DNS Resolver)
spoke_virtual_networks = {
  common_services_internet = {
    spoke_vnet_resource_id = "<common_services_vnet_id>"
    hub_key                = "hub_internet"
  }
  common_services_intranet = {
    spoke_vnet_resource_id = "<common_services_vnet_id>"
    hub_key                = "hub_intranet"
  }
}
```

Mesh peering between hubs is automatically handled by the core pattern's `mesh_peering_enabled` setting (default: `true`). The common services VNet is peered to both hubs via spoke peering entries.
