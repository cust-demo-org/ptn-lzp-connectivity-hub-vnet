# Full Dual-Hub example

This deploys a dual-hub topology — an internet egress/ingress hub and an intranet ingress hub in `southeastasia`, both peered to a common services VNet.

## Architecture

- **Internet Hub** (`hub_internet`): Azure Firewall (Standard) + NAT Gateway + Bastion, non-routable `10.0.0.0/16`
- **Intranet Hub** (`hub_intranet`): Azure Firewall (Standard) only, routable `10.1.0.0/16`
- **Common Services VNet**: `10.2.0.0/16` with DNS resolver subnet, peered to both hubs

## Features tested

- Dual-hub VNets with mesh peering
- NAT Gateway on internet hub with public IP
- Bastion on internet hub (Standard SKU)
- Two NSGs — one per hub, associated via `nsg_key`
- Hub-to-spoke peering to common services VNet
- Flow logs with traffic analytics for both hubs
- Storage account for flow log storage
- Log Analytics workspace created by wrapper
- DDoS protection plan disabled (cost savings in examples)
