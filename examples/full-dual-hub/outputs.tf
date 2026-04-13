output "virtual_network_ids" {
  value       = module.hub.virtual_network_ids
  description = "Virtual network resource IDs."
}

output "resource_group_ids" {
  value       = module.hub.resource_group_ids
  description = "Resource group IDs."
}

output "nsg_resource_ids" {
  value       = module.hub.nsg_resource_ids
  description = "Network Security Group resource IDs."
}

output "nat_gateway_resource_ids" {
  value       = module.hub.nat_gateway_resource_ids
  description = "NAT Gateway resource IDs."
}

output "public_ip_ids" {
  value       = module.hub.public_ip_ids
  description = "Public IP resource IDs."
}

output "firewall_ids" {
  value       = module.hub.firewall_ids
  description = "Azure Firewall resource IDs."
}

output "firewall_policy_ids" {
  value       = module.hub.firewall_policy_ids
  description = "Firewall Policy resource IDs."
}

output "network_watcher_id" {
  value       = module.hub.network_watcher_id
  description = "Network Watcher resource ID."
}

output "private_dns_resolver_ids" {
  value       = module.hub.private_dns_resolver_ids
  description = "Private DNS Resolver resource IDs."
}

output "private_dns_resolver_inbound_endpoint_ips" {
  value       = module.hub.private_dns_resolver_inbound_endpoint_ips
  description = "Private DNS Resolver inbound endpoint IP addresses."
}
