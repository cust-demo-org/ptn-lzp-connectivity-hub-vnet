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

  # Subnet resource ID lookup: resolve "vnet_key/subnet_key" -> subnet resource ID
  subnet_resource_ids = {
    for pair in flatten([
      for vnet_key, mod in module.virtual_network : [
        for subnet_key, subnet in mod.subnets : {
          key         = "${vnet_key}/${subnet_key}"
          resource_id = subnet.resource_id
        }
      ]
    ]) : pair.key => pair.resource_id
  }

  # Public IP resource ID lookup
  public_ip_resource_ids = { for key, mod in module.public_ip : key => mod.public_ip_id }

  # Firewall policy resource ID lookup: resolve firewall_policy_key -> resource ID
  firewall_policy_resource_ids = { for key, mod in module.firewall_policy : key => mod.resource_id }

  # Firewall resource ID lookup
  firewall_resource_ids = { for key, mod in module.firewall : key => mod.resource_id }

  # Network Watcher defaults — pre-computed to avoid inline data source references
  # that can cause "known after apply" deferral when callers use depends_on.
  # When network_watcher_id is null, we construct the Azure-standard default from
  # data.azurerm_client_config, which is always available at plan time in this module.
  # However, if a caller uses depends_on on this module, Terraform defers ALL data
  # sources inside the module, making the constructed ID "known after apply" and
  # forcing azapi_resource.flow_logs replacement on every plan.
  # To avoid this, we compute the default here and use it consistently.
  flowlog_location             = var.flowlog_configuration != null ? coalesce(var.flowlog_configuration.location, var.location) : var.location
  flowlog_network_watcher_name = var.flowlog_configuration != null ? coalesce(var.flowlog_configuration.network_watcher_name, "NetworkWatcher_${local.flowlog_location}") : null
  flowlog_resource_group_name  = var.flowlog_configuration != null ? coalesce(var.flowlog_configuration.resource_group_name, "NetworkWatcherRG") : null
  flowlog_network_watcher_id = var.flowlog_configuration != null ? coalesce(
    var.flowlog_configuration.network_watcher_id,
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.flowlog_resource_group_name}/providers/Microsoft.Network/networkWatchers/${local.flowlog_network_watcher_name}"
  ) : null
}
