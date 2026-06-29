output "resource_groups" {
  value = { for key, mod in module.resource_group : key => {
    resource_id = mod.resource_id
    name        = mod.name
  } }
  description = "Map of resource group keys to their resource IDs and names."
}

output "network_security_groups" {
  value = { for key, mod in module.network_security_group : key => {
    resource_id = mod.resource_id
    name        = mod.name
  } }
  description = "Map of NSG keys to their resource IDs and names."
}

output "route_tables" {
  value = { for key, mod in module.route_table : key => {
    resource_id = mod.resource_id
    name        = mod.name
  } }
  description = "Map of route table keys to their resource IDs and names."
}

output "nat_gateways" {
  value = { for key, mod in module.nat_gateway : key => {
    resource_id = mod.resource_id
    name        = mod.resource.name
  } }
  description = "Map of NAT gateway keys to their resource IDs and names."
}

output "public_ips" {
  value = { for key, mod in module.public_ip : key => {
    resource_id       = mod.resource_id
    name              = mod.name
    public_ip_address = mod.public_ip_address
  } }
  description = "Map of public IP keys to their resource IDs, names, and assigned IP addresses."
}

output "virtual_networks" {
  value = { for key, mod in module.virtual_network : key => {
    resource_id    = mod.resource_id
    name           = mod.name
    address_spaces = mod.address_spaces
    subnets        = mod.subnets
    peerings       = mod.peerings
  } }
  description = "Map of VNet keys to their resource IDs, names, address spaces, subnet details, and peering details."
}

output "virtual_network_gateways" {
  value = { for key, mod in module.virtual_network_gateway : key => {
    resource_id = mod.resource_id
    name        = mod.virtual_network_gateway.name
  } }
  description = "Map of virtual network gateway keys to their resource IDs and names."
}

output "firewall_policies" {
  value = { for key, mod in module.firewall_policy : key => {
    resource_id = mod.resource_id
    name        = mod.resource.name
  } }
  description = "Map of firewall policy keys to their resource IDs and names."
}

output "firewalls" {
  value = { for key, mod in module.firewall : key => {
    resource_id = mod.resource_id
    name        = mod.resource.name
  } }
  description = "Map of firewall keys to their resource IDs and names."
}

output "private_dns_resolvers" {
  value = { for key, mod in module.private_dns_resolver : key => {
    resource_id          = mod.resource_id
    name                 = mod.name
    inbound_endpoint_ips = mod.inbound_endpoint_ips
  } }
  description = "Map of private DNS resolver keys to their resource IDs, names, and inbound endpoint IPs (map of inbound endpoint key to private IP address)."
}

output "private_dns_zones" {
  value = { for key, mod in module.private_dns_zone : key => {
    resource_id = mod.resource_id
    name        = mod.resource.name
  } }
  description = "Map of Private DNS Zone keys to their resource IDs and names."
}

output "byo_private_dns_zones" {
  value = { for key, zone in var.byo_private_dns_zones : key => {
    resource_id = zone.private_dns_zone_id
    name        = split("/", zone.private_dns_zone_id)[length(split("/", zone.private_dns_zone_id)) - 1]
  } }
  description = "Map of BYO Private DNS Zone keys to their resource IDs and names. Empty map when no byo_private_dns_zones are configured."
}

output "network_watcher" {
  value = var.flowlog_configuration != null ? {
    resource_id = module.network_watcher[0].resource_id
    flow_logs   = module.network_watcher[0].resource_flow_log
  } : null
  description = "Network Watcher resource ID and flow log details. Null when flowlog_configuration is not provided."
}
