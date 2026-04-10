# Full Dual-Hub example

This deploys a dual-hub topology — an internet egress/ingress hub and an intranet ingress hub in `southeastasia`, with external resources for flow log storage integrated via pattern cross-references.

## Architecture

- **Internet Hub** (`vnet_internet`): Azure Firewall (Standard) + NAT Gateway, non-routable `10.0.0.0/16`
- **Intranet Hub** (`vnet_intranet`): Azure Firewall (Standard) only, routable `10.1.0.0/16`
- **Flowlog VNet** (`vnet-flowlog-dualhub`): External VNet `10.10.0.0/24` with PEP subnet, peered to both hubs
- **Storage Account**: External storage account for flow logs, accessed via blob private endpoint
- **Private DNS Zone**: External `privatelink.blob.core.windows.net` linked to both hub VNets via `byo_private_dns_zone_virtual_network_links`

## Features tested

- Dual-hub VNets with firewall (Standard SKU, forced tunnelling with management IP)
- NAT Gateway on internet hub with pattern-managed public IP
- Two NSGs — one per hub, associated via `network_security_group = { key }`
- VNet peering from hub VNets to external flowlog VNet (with reverse peering)
- External storage account with blob private endpoint for flow log storage
- BYO private dns zone virtual network links connecting external blob DNS zone to pattern VNets
- Flow logs for both hub VNets referencing external storage account
- Network Watcher auto-provisioned by flow log configuration
- Dynamic cross-references built in `main.tf` locals (merging with `var` values)

## Notes
Usually external resources would already be created, but are included inline here for visibility and simplicity in the example. In a real deployment, only tfvars would be needed to reference these external resources from the pattern module