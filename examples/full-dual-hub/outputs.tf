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
