# Individual resource module outputs

output "virtual_network_ids" {
  value       = local.vnet_resource_ids
  description = "A map of virtual network key to VNet resource ID."
}

output "firewall_ids" {
  value       = local.firewall_resource_ids
  description = "A map of firewall key to Azure Firewall resource ID."
}

output "firewall_policy_ids" {
  value       = local.firewall_policy_resource_ids
  description = "A map of firewall policy key to Firewall Policy resource ID."
}

output "public_ip_ids" {
  value       = local.public_ip_resource_ids
  description = "A map of public IP key to Public IP resource ID."
}

output "route_table_ids" {
  value       = local.rt_resource_ids
  description = "A map of route table key to Route Table resource ID."
}

output "private_dns_zone_ids" {
  value       = { for key, mod in module.private_dns_zone : key => mod.resource_id }
  description = "A map of private DNS zone key to Private DNS Zone resource ID."
}

output "private_dns_resolver_ids" {
  value       = local.dns_resolver_resource_ids
  description = "A map of private DNS resolver key to DNS Resolver resource ID."
}

output "private_dns_resolver_inbound_endpoint_ips" {
  value       = { for key, mod in module.private_dns_resolver : key => mod.inbound_endpoint_ips }
  description = "A map of private DNS resolver key to a map of inbound endpoint key to private IP address."
}

output "virtual_network_gateway_ids" {
  value       = { for key, mod in module.virtual_network_gateway : key => mod.resource_id }
  description = "A map of virtual network gateway key to VNet Gateway resource ID."
}

# Supplementary resource outputs

output "resource_group_ids" {
  value       = local.resource_group_resource_ids
  description = "A map of resource group key to resource group resource ID."
}

output "resource_group_names" {
  value       = local.resource_group_names
  description = "A map of resource group key to resource group name."
}

output "nsg_resource_ids" {
  value       = local.nsg_resource_ids
  description = "A map of NSG key to Network Security Group resource ID."
}

output "nat_gateway_resource_ids" {
  value       = local.nat_gateway_resource_ids
  description = "A map of NAT gateway key to NAT Gateway resource ID."
}

output "network_watcher_id" {
  value       = try(module.network_watcher[0].resource_id, null)
  description = "The resource ID of the Network Watcher, or null if not created."
}
