# PLZ Connectivity Hub VNet Pattern

This Terraform root module provisions Azure Platform Landing Zone (PLZ) connectivity virtual network hub infrastructure using [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) exclusively.

## Overview

The pattern wraps the AVM core pattern module [`Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm) v0.16.14 with supplementary AVM resource modules for NSGs, NAT Gateways, Log Analytics, storage accounts, managed identities, and VNet peering.

## Features

- **Single or multi-hub topologies** — deploy one or more hub VNets (e.g., internet egress + intranet ingress)
- **Configuration-driven** — all parameters passthrough from `terraform.tfvars`
- **Key-based cross-references** — subnets reference NSGs and NAT Gateways by map key (`nsg_key`, `nat_gateway_key`)
- **BYO resource support** — bring your own Log Analytics workspace or storage account
- **Hub-to-spoke peering** — bidirectional VNet peering to existing spoke VNets
- **Flow logs with traffic analytics** — Network Watcher integration for VNet flow monitoring
- **Secure by default** — public network access disabled, TLS 1.2+, default-deny NSG posture

## Usage

```hcl
module "hub" {
  source  = "Azure/avm-ptn-lzp-connectivity-hub-vnet/azurerm"
  version = "x.x.x"

  location = "southeastasia"

  resource_groups = {
    rg_hub = { name = "rg-hub-sea" }
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
            nsg_key          = "nsg_default"
          }
        }
      }
      firewall = { subnet_address_prefix = "10.0.0.0/26" }
      bastion  = { subnet_address_prefix = "10.0.0.64/26" }
    }
  }

  network_security_groups = {
    nsg_default = {
      name               = "nsg-default"
      resource_group_key = "rg_hub"
    }
  }

  log_analytics_workspace_configuration = {
    name               = "law-hub-sea"
    resource_group_key = "rg_hub"
  }
}
```