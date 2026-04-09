locals {
  # Resource group name lookup: resolve resource_group_key -> resource group name
  resource_group_names = { for key, mod in module.resource_group : key => mod.name }

  # Resource group ID lookup: resolve resource_group_key -> resource group resource ID
  resource_group_resource_ids = { for key, mod in module.resource_group : key => mod.resource_id }

  # NSG resource ID lookup: resolve NSG key -> resource ID for subnet associations
  nsg_resource_ids = { for key, mod in module.network_security_group : key => mod.resource_id }

  # Route table resource ID lookup: resolve route_table_key -> resource ID for subnet associations
  rt_resource_ids = { for key, mod in module.route_table : key => mod.resource_id }

  # NAT gateway resource ID lookup: resolve NAT gateway key -> resource ID for subnet associations
  nat_gateway_resource_ids = { for key, mod in module.nat_gateway : key => mod.resource_id }

  # VNet resource ID lookup: resolve virtual_network_key -> resource ID
  vnet_resource_ids = { for key, mod in module.virtual_network : key => mod.resource_id }

  # Public IP resource ID lookup
  public_ip_resource_ids = { for key, mod in module.public_ip : key => mod.public_ip_id }

  # Firewall policy resource ID lookup: resolve firewall_policy_key -> resource ID
  firewall_policy_resource_ids = { for key, mod in module.firewall_policy : key => mod.resource_id }

  # Firewall resource ID lookup
  firewall_resource_ids = { for key, mod in module.firewall : key => mod.resource_id }
}
