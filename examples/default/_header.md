# Default example

This deploys the minimal PLZ Connectivity Hub VNet pattern — a single hub virtual network with Azure Firewall, Bastion, one NSG, and a wrapper-created Log Analytics workspace.

## Features tested

- Single hub VNet with `10.0.0.0/16` address space
- Azure Firewall (Standard SKU)
- Azure Bastion (Standard SKU)
- One Network Security Group associated via `nsg_key`
- Log Analytics workspace created by the wrapper (30-day retention)
- VPN/ExpressRoute gateways, private DNS zones, and DNS resolver disabled
