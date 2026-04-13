data "azurerm_client_config" "current" {}

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition = alltrue([
        for key, v in var.network_security_groups : contains(keys(var.resource_groups), v.resource_group_key)
      ])
      error_message = "One or more network_security_groups entries reference a resource_group_key that does not exist in var.resource_groups."
    }
    precondition {
      condition = alltrue([
        for key, v in var.route_tables : contains(keys(var.resource_groups), v.resource_group_key)
      ])
      error_message = "One or more route_tables entries reference a resource_group_key that does not exist in var.resource_groups."
    }
    precondition {
      condition = alltrue([
        for key, v in var.nat_gateways : contains(keys(var.resource_groups), v.resource_group_key)
      ])
      error_message = "One or more nat_gateways entries reference a resource_group_key that does not exist in var.resource_groups."
    }
    precondition {
      condition = alltrue([
        for key, v in var.virtual_networks : contains(keys(var.resource_groups), v.resource_group_key)
      ])
      error_message = "One or more virtual_networks entries reference a resource_group_key that does not exist in var.resource_groups."
    }
    precondition {
      condition = alltrue(flatten([
        for vnet_key, vnet in var.virtual_networks : [
          for sk, sv in vnet.subnets :
          sv.network_security_group == null || sv.network_security_group.key == null || contains(keys(var.network_security_groups), sv.network_security_group.key)
        ]
      ]))
      error_message = "One or more subnets reference a network_security_group.key that does not exist in var.network_security_groups."
    }
    precondition {
      condition = alltrue(flatten([
        for vnet_key, vnet in var.virtual_networks : [
          for sk, sv in vnet.subnets :
          sv.route_table == null || sv.route_table.key == null || contains(keys(var.route_tables), sv.route_table.key)
        ]
      ]))
      error_message = "One or more subnets reference a route_table.key that does not exist in var.route_tables."
    }
    precondition {
      condition = alltrue(flatten([
        for vnet_key, vnet in var.virtual_networks : [
          for sk, sv in vnet.subnets :
          sv.nat_gateway == null || sv.nat_gateway.key == null || contains(keys(var.nat_gateways), sv.nat_gateway.key)
        ]
      ]))
      error_message = "One or more subnets reference a nat_gateway.key that does not exist in var.nat_gateways."
    }
    precondition {
      condition = alltrue([
        for key, v in var.firewalls :
        v.firewall_policy == null || v.firewall_policy.key == null || contains(keys(var.firewall_policies), v.firewall_policy.key)
      ])
      error_message = "One or more firewalls reference a firewall_policy.key that does not exist in var.firewall_policies."
    }
    precondition {
      condition = alltrue([
        for key, v in var.virtual_network_gateways :
        v.virtual_network == null || v.virtual_network.key == null || contains(keys(var.virtual_networks), v.virtual_network.key)
      ])
      error_message = "One or more virtual_network_gateways reference a virtual_network.key that does not exist in var.virtual_networks."
    }
    precondition {
      condition = alltrue(flatten([
        for dns_key, dns in var.private_dns_zones : [
          for vnl_key, vnl in dns.virtual_network_links :
          vnl.virtual_network == null || vnl.virtual_network.key == null || contains(keys(var.virtual_networks), vnl.virtual_network.key)
        ]
      ]))
      error_message = "One or more private_dns_zones virtual_network_links reference a virtual_network.key that does not exist in var.virtual_networks."
    }
    precondition {
      condition = alltrue([
        for zone_key, zone in var.byo_private_dns_zones : alltrue([
          for vnl_key, vnl in zone.virtual_network_links :
          vnl.virtual_network.key == null || contains(keys(var.virtual_networks), vnl.virtual_network.key)
        ])
      ])
      error_message = "BYO DNS zone link references a virtual_network.key that does not exist in virtual_networks."
    }
    precondition {
      condition = alltrue([
        for key, v in var.private_dns_resolvers :
        contains(keys(var.resource_groups), v.resource_group_key)
      ])
      error_message = "One or more private_dns_resolvers entries reference a resource_group_key that does not exist in var.resource_groups."
    }
    precondition {
      condition = alltrue([
        for key, v in var.private_dns_resolvers :
        v.virtual_network.key == null || contains(keys(var.virtual_networks), v.virtual_network.key)
      ])
      error_message = "One or more private_dns_resolvers entries reference a virtual_network.key that does not exist in var.virtual_networks."
    }
  }
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.2"

  for_each = var.resource_groups

  enable_telemetry = var.enable_telemetry
  name             = each.value.name
  location         = coalesce(each.value.location, var.location)
  tags             = merge(var.tags, each.value.tags)
  lock             = each.value.lock
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "network_security_group" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  for_each = var.network_security_groups

  enable_telemetry    = var.enable_telemetry
  name                = each.value.name
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  location            = coalesce(each.value.location, var.location)
  security_rules      = each.value.security_rules
  diagnostic_settings = each.value.diagnostic_settings
  lock                = each.value.lock
  tags                = merge(var.tags, each.value.tags)
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  for_each = var.route_tables

  enable_telemetry              = var.enable_telemetry
  name                          = each.value.name
  resource_group_name           = local.resource_group_names[each.value.resource_group_key]
  location                      = coalesce(each.value.location, var.location)
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = each.value.routes
  lock                          = each.value.lock
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
  tags = merge(var.tags, each.value.tags)
}

module "nat_gateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.3.2"

  for_each = var.nat_gateways

  enable_telemetry        = var.enable_telemetry
  name                    = each.value.name
  parent_id               = local.resource_group_resource_ids[each.value.resource_group_key]
  location                = coalesce(each.value.location, var.location)
  sku_name                = each.value.sku_name
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  zones                   = each.value.zones
  public_ips              = each.value.public_ips
  public_ip_configuration = each.value.public_ip_configuration
  public_ip_resource_ids = setunion(
    each.value.public_ip_addresses.ids,
    toset([for k in each.value.public_ip_addresses.keys : local.public_ip_resource_ids[k]])
  )
  diagnostic_settings = each.value.diagnostic_settings
  lock                = each.value.lock
  tags                = merge(var.tags, each.value.tags)
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  for_each = var.virtual_networks

  enable_telemetry = var.enable_telemetry
  name             = each.value.name
  parent_id        = local.resource_group_resource_ids[each.value.resource_group_key]
  location         = coalesce(each.value.location, var.location)
  address_space    = each.value.address_space

  dns_servers = each.value.dns_servers != null ? { dns_servers = each.value.dns_servers } : null
  ddos_protection_plan = each.value.ddos_protection_plan != null ? {
    id     = each.value.ddos_protection_plan.resource_id
    enable = each.value.ddos_protection_plan.enable
  } : null
  encryption              = each.value.encryption
  bgp_community           = each.value.bgp_community
  enable_vm_protection    = each.value.enable_vm_protection
  flow_timeout_in_minutes = each.value.flow_timeout_in_minutes
  ipam_pools              = each.value.ipam_pools

  subnets = {
    for sk, sv in each.value.subnets : sk => merge(sv, {
      network_security_group = sv.network_security_group != null ? (
        sv.network_security_group.key != null ? {
          id = local.nsg_resource_ids[sv.network_security_group.key]
          } : sv.network_security_group.resource_id != null ? {
          id = sv.network_security_group.resource_id
        } : null
      ) : null
      route_table = sv.route_table != null ? (
        sv.route_table.key != null ? {
          id = local.rt_resource_ids[sv.route_table.key]
          } : sv.route_table.resource_id != null ? {
          id = sv.route_table.resource_id
        } : null
      ) : null
      nat_gateway = sv.nat_gateway != null ? (
        sv.nat_gateway.key != null ? {
          id = local.nat_gateway_resource_ids[sv.nat_gateway.key]
          } : sv.nat_gateway.resource_id != null ? {
          id = sv.nat_gateway.resource_id
        } : null
      ) : null
      role_assignments = {
        for ra_key, ra in sv.role_assignments : ra_key => {
          role_definition_id_or_name             = ra.role_definition_id_or_name
          principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
          description                            = ra.description
          skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
          condition                              = ra.condition
          condition_version                      = ra.condition_version
          delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
          principal_type                         = ra.principal_type
        }
      }
    })
  }

  peerings            = each.value.peerings
  diagnostic_settings = each.value.diagnostic_settings
  lock                = each.value.lock
  tags                = merge(var.tags, each.value.tags)
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "virtual_network_gateway" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm//modules/virtual-network-gateway"
  version = "0.16.14"

  for_each = var.virtual_network_gateways

  enable_telemetry = var.enable_telemetry
  name             = each.value.name
  location         = coalesce(each.value.location, var.location)
  parent_id        = local.resource_group_resource_ids[each.value.resource_group_key]
  type             = each.value.type
  sku              = each.value.sku
  tags             = merge(var.tags, each.value.tags)

  virtual_network_id = each.value.virtual_network != null ? (
    each.value.virtual_network.key != null ? local.vnet_resource_ids[each.value.virtual_network.key] : each.value.virtual_network.resource_id
  ) : null
  subnet_address_prefix   = each.value.subnet_address_prefix
  subnet_creation_enabled = each.value.subnet_creation_enabled
  virtual_network_gateway_subnet_id = each.value.gateway_subnet != null ? (
    each.value.gateway_subnet.vnet_key != null && each.value.gateway_subnet.subnet_key != null ?
    local.subnet_resource_ids["${each.value.gateway_subnet.vnet_key}/${each.value.gateway_subnet.subnet_key}"] :
    each.value.gateway_subnet.resource_id
  ) : null
  edge_zone = each.value.edge_zone

  ip_configurations = {
    for k, v in each.value.ip_configurations : k => merge(v, {
      public_ip = v.public_ip_address != null ? {
        creation_enabled = false
        id               = v.public_ip_address.key != null ? local.public_ip_resource_ids[v.public_ip_address.key] : v.public_ip_address.resource_id
      } : v.public_ip
    })
  }
  local_network_gateways = each.value.local_network_gateways
  express_route_circuits = each.value.express_route_circuits

  express_route_remote_vnet_traffic_enabled = each.value.express_route_remote_vnet_traffic_enabled
  express_route_virtual_wan_traffic_enabled = each.value.express_route_virtual_wan_traffic_enabled
  hosted_on_behalf_of_public_ip_enabled     = each.value.hosted_on_behalf_of_public_ip_enabled

  vpn_active_active_enabled                 = each.value.vpn_active_active_enabled
  vpn_bgp_enabled                           = each.value.vpn_bgp_enabled
  vpn_bgp_route_translation_for_nat_enabled = each.value.vpn_bgp_route_translation_for_nat_enabled
  vpn_bgp_settings                          = each.value.vpn_bgp_settings
  vpn_custom_route                          = each.value.vpn_custom_route
  vpn_default_local_network_gateway_id      = each.value.vpn_default_local_network_gateway_id
  vpn_dns_forwarding_enabled                = each.value.vpn_dns_forwarding_enabled
  vpn_generation                            = each.value.vpn_generation
  vpn_ip_sec_replay_protection_enabled      = each.value.vpn_ip_sec_replay_protection_enabled
  vpn_point_to_site                         = each.value.vpn_point_to_site
  vpn_policy_groups                         = each.value.vpn_policy_groups
  vpn_private_ip_address_enabled            = each.value.vpn_private_ip_address_enabled
  vpn_type                                  = each.value.vpn_type

  route_table_creation_enabled              = each.value.route_table_creation_enabled
  route_table_name                          = each.value.route_table_name
  route_table_bgp_route_propagation_enabled = each.value.route_table_bgp_route_propagation_enabled
  route_table_resource_group_name           = each.value.route_table_resource_group_name
  route_table_tags                          = each.value.route_table_tags

  retry    = each.value.retry
  timeouts = each.value.timeouts

  diagnostic_settings_virtual_network_gateway = each.value.diagnostic_settings
}

module "public_ip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  for_each = var.public_ips

  enable_telemetry        = var.enable_telemetry
  name                    = each.value.name
  resource_group_name     = local.resource_group_names[each.value.resource_group_key]
  location                = coalesce(each.value.location, var.location)
  allocation_method       = each.value.allocation_method
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  zones                   = each.value.zones
  ip_version              = each.value.ip_version
  domain_name_label       = each.value.domain_name_label
  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  ip_tags                 = each.value.ip_tags
  public_ip_prefix_id     = each.value.public_ip_prefix_id
  reverse_fqdn            = each.value.reverse_fqdn
  edge_zone               = each.value.edge_zone
  diagnostic_settings     = each.value.diagnostic_settings
  lock                    = each.value.lock
  tags                    = merge(var.tags, each.value.tags)
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  for_each = var.firewall_policies

  enable_telemetry                                  = var.enable_telemetry
  name                                              = each.value.name
  resource_group_name                               = local.resource_group_names[each.value.resource_group_key]
  location                                          = coalesce(each.value.location, var.location)
  firewall_policy_sku                               = each.value.sku
  firewall_policy_base_policy_id                    = each.value.base_policy_id
  firewall_policy_auto_learn_private_ranges_enabled = each.value.auto_learn_private_ranges_enabled
  firewall_policy_dns                               = each.value.dns
  firewall_policy_explicit_proxy                    = each.value.explicit_proxy
  firewall_policy_identity                          = each.value.identity
  firewall_policy_insights                          = each.value.insights
  firewall_policy_intrusion_detection               = each.value.intrusion_detection
  firewall_policy_private_ip_ranges                 = each.value.private_ip_ranges
  firewall_policy_sql_redirect_allowed              = each.value.sql_redirect_allowed
  firewall_policy_threat_intelligence_mode          = each.value.threat_intelligence_mode
  firewall_policy_threat_intelligence_allowlist     = each.value.threat_intelligence_allowlist
  firewall_policy_tls_certificate                   = each.value.tls_certificate
  firewall_policy_timeouts                          = each.value.timeouts
  diagnostic_settings                               = each.value.diagnostic_settings
  lock                                              = each.value.lock
  tags                                              = merge(var.tags, each.value.tags)
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"

  for_each = var.firewalls

  enable_telemetry    = var.enable_telemetry
  name                = each.value.name
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  location            = coalesce(each.value.location, var.location)
  firewall_sku_name   = each.value.sku_name
  firewall_sku_tier   = each.value.sku_tier
  firewall_policy_id = each.value.firewall_policy != null ? (
    each.value.firewall_policy.key != null ? local.firewall_policy_resource_ids[each.value.firewall_policy.key] : each.value.firewall_policy.resource_id
  ) : null
  ip_configurations = {
    for k, v in each.value.ip_configuration : k => {
      name                 = v.name
      public_ip_address_id = v.public_ip_address != null ? (v.public_ip_address.key != null ? local.public_ip_resource_ids[v.public_ip_address.key] : v.public_ip_address.resource_id) : null
      subnet_id            = v.subnet != null ? (v.subnet.vnet_key != null && v.subnet.subnet_key != null ? local.subnet_resource_ids["${v.subnet.vnet_key}/${v.subnet.subnet_key}"] : v.subnet.resource_id) : null
    }
  }
  firewall_management_ip_configuration = each.value.management_ip_configuration != null ? {
    name                 = each.value.management_ip_configuration.name
    public_ip_address_id = each.value.management_ip_configuration.public_ip_address != null ? (each.value.management_ip_configuration.public_ip_address.key != null ? local.public_ip_resource_ids[each.value.management_ip_configuration.public_ip_address.key] : each.value.management_ip_configuration.public_ip_address.resource_id) : null
    subnet_id            = each.value.management_ip_configuration.subnet.vnet_key != null && each.value.management_ip_configuration.subnet.subnet_key != null ? local.subnet_resource_ids["${each.value.management_ip_configuration.subnet.vnet_key}/${each.value.management_ip_configuration.subnet.subnet_key}"] : each.value.management_ip_configuration.subnet.resource_id
  } : null
  firewall_private_ip_ranges = each.value.private_ip_ranges
  firewall_virtual_hub       = each.value.virtual_hub
  firewall_zones             = each.value.zones
  firewall_timeouts          = each.value.timeouts
  diagnostic_settings        = each.value.diagnostic_settings
  lock                       = each.value.lock
  tags                       = merge(var.tags, each.value.tags)
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "private_dns_resolver" {
  source  = "Azure/avm-res-network-dnsresolver/azurerm"
  version = "0.8.0"

  for_each = var.private_dns_resolvers

  name                = each.value.name
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  location            = coalesce(each.value.location, var.location)
  virtual_network_resource_id = each.value.virtual_network.key != null ? (
    local.vnet_resource_ids[each.value.virtual_network.key]
  ) : each.value.virtual_network.resource_id
  inbound_endpoints = {
    for iep_key, iep in each.value.inbound_endpoints : iep_key => {
      name = iep.name
      subnet_name = iep.subnet.key != null ? (
        var.virtual_networks[each.value.virtual_network.key].subnets[iep.subnet.key].name
      ) : iep.subnet.name
      private_ip_allocation_method = iep.private_ip_allocation_method
      private_ip_address           = iep.private_ip_address
      tags                         = iep.tags
    }
  }
  outbound_endpoints = {
    for oep_key, oep in each.value.outbound_endpoints : oep_key => {
      name = oep.name
      subnet_name = oep.subnet.key != null ? (
        var.virtual_networks[each.value.virtual_network.key].subnets[oep.subnet.key].name
      ) : oep.subnet.name
      tags = oep.tags
      forwarding_ruleset = oep.forwarding_ruleset != null ? {
        for rs_key, rs in oep.forwarding_ruleset : rs_key => {
          name                                                = rs.name
          link_with_outbound_endpoint_virtual_network         = rs.link_with_outbound_endpoint_virtual_network
          metadata_for_outbound_endpoint_virtual_network_link = rs.metadata_for_outbound_endpoint_virtual_network_link
          tags                                                = rs.tags
          additional_virtual_network_links = {
            for link_key, link in rs.additional_virtual_network_links : link_key => {
              name = link.name
              vnet_id = link.virtual_network.key != null ? (
                local.vnet_resource_ids[link.virtual_network.key]
              ) : link.virtual_network.resource_id
              metadata = link.metadata
            }
          }
          rules = rs.rules
        }
      } : null
    }
  }
  lock = each.value.lock
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
  tags             = merge(var.tags, each.value.tags)
  enable_telemetry = var.enable_telemetry
}

module "private_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  for_each = var.private_dns_zones

  enable_telemetry = var.enable_telemetry
  domain_name      = each.value.domain_name
  parent_id        = local.resource_group_resource_ids[each.value.resource_group_key]
  virtual_network_links = {
    for vnl_k, vnl in each.value.virtual_network_links : vnl_k => {
      name = vnl.name
      virtual_network_id = vnl.virtual_network != null ? (
        vnl.virtual_network.key != null ? local.vnet_resource_ids[vnl.virtual_network.key] : vnl.virtual_network.resource_id
      ) : null
      registration_enabled                   = vnl.registration_enabled
      resolution_policy                      = vnl.resolution_policy
      private_dns_zone_supports_private_link = vnl.private_dns_zone_supports_private_link
      tags                                   = merge(var.tags, vnl.tags)
    }
  }
  lock = each.value.lock
  tags = merge(var.tags, each.value.tags)
  role_assignments = {
    for ra_key, ra in each.value.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
}

module "private_dns_zone_virtual_network_link" { # separate module to link BYO private DNS to pattern-managed VNets
  source  = "Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link"
  version = "0.5.0"

  for_each = {
    for item in flatten([
      for zone_key, zone in var.byo_private_dns_zones : [
        for vnl_key, vnl in zone.virtual_network_links : {
          key                                    = "${zone_key}/${vnl_key}"
          name                                   = vnl.name
          private_dns_zone_id                    = zone.private_dns_zone_id
          virtual_network                        = vnl.virtual_network
          registration_enabled                   = vnl.registration_enabled
          resolution_policy                      = vnl.resolution_policy
          private_dns_zone_supports_private_link = vnl.private_dns_zone_supports_private_link
          tags                                   = vnl.tags
        }
      ]
    ]) : item.key => item
  }

  name      = each.value.name
  parent_id = each.value.private_dns_zone_id
  virtual_network_id = (
    each.value.virtual_network.key != null
    ? local.vnet_resource_ids[each.value.virtual_network.key]
    : each.value.virtual_network.resource_id
  )
  registration_enabled                   = each.value.registration_enabled
  resolution_policy                      = each.value.resolution_policy
  private_dns_zone_supports_private_link = each.value.private_dns_zone_supports_private_link
  tags                                   = merge(var.tags, each.value.tags)
}

# Azure auto-creates a Network Watcher (NetworkWatcher_<region>) in the
# NetworkWatcherRG resource group when the first VNet is deployed in a region.
# This provisioning is asynchronous and can take a few minutes. The time_sleep
# resource ensures the Network Watcher exists before flow logs are configured.
resource "time_sleep" "wait_for_network_watcher" {
  count = var.flowlog_configuration != null ? 1 : 0

  create_duration = var.network_watcher_creation_delay

  depends_on = [module.virtual_network]
}

module "network_watcher" {
  source  = "Azure/avm-res-network-networkwatcher/azurerm"
  version = "0.3.2"

  count = var.flowlog_configuration != null ? 1 : 0

  enable_telemetry     = var.enable_telemetry
  network_watcher_id   = local.flowlog_network_watcher_id
  network_watcher_name = local.flowlog_network_watcher_name
  resource_group_name  = local.flowlog_resource_group_name
  location             = local.flowlog_location
  flow_logs = var.flowlog_configuration.flow_logs != null ? {
    for k, fl in var.flowlog_configuration.flow_logs : k => {
      enabled = fl.enabled
      name    = fl.name
      target_resource_id = fl.virtual_network != null ? (
        fl.virtual_network.key != null ? local.vnet_resource_ids[fl.virtual_network.key] : fl.virtual_network.resource_id
      ) : null
      retention_policy   = fl.retention_policy
      storage_account_id = fl.storage_account_id
      traffic_analytics  = fl.traffic_analytics
      version            = fl.version
    }
  } : null
  lock = var.flowlog_configuration.lock
  role_assignments = {
    for ra_key, ra in var.flowlog_configuration.role_assignments : ra_key => {
      role_definition_id_or_name             = ra.role_definition_id_or_name
      principal_id                           = ra.assign_to_caller ? data.azurerm_client_config.current.object_id : ra.principal_id
      description                            = ra.description
      skip_service_principal_aad_check       = ra.skip_service_principal_aad_check
      condition                              = ra.condition
      condition_version                      = ra.condition_version
      delegated_managed_identity_resource_id = ra.delegated_managed_identity_resource_id
      principal_type                         = ra.principal_type
    }
  }
  tags = merge(var.tags, var.flowlog_configuration.tags)

  depends_on = [time_sleep.wait_for_network_watcher]
}
