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

