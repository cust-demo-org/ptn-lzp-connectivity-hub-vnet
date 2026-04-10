# ---------------------------------------------------------------------------
# Full Dual-Hub Example
# ---------------------------------------------------------------------------
# Dual internet/intranet hub VNets with NAT gateway and flow logs.
# Includes external resources (RG, VNet, storage account, private endpoint,
# private DNS zone) wired into the pattern via cross-references.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# External Resources — created outside the pattern module
# ---------------------------------------------------------------------------
# These resources demonstrate how externally-managed infrastructure
# integrates with the hub pattern via peerings, BYO DNS zone links,
# and flowlog storage account references.
# Usually external resources would already be created, but are included inline here
# for visibility and simplicity in the example. In a real deployment, only 
# tfvars would be needed to reference these external resources from the pattern module
# using their resource IDs.
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "flowlog" {
  name     = "rg-flowlog-dualhub"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "flowlog" {
  name                = "vnet-flowlog-dualhub"
  location            = azurerm_resource_group.flowlog.location
  resource_group_name = azurerm_resource_group.flowlog.name
  address_space       = ["10.10.0.0/24"]
  tags                = var.tags
}

resource "azurerm_subnet" "pep" {
  name                 = "snet-pep"
  resource_group_name  = azurerm_resource_group.flowlog.name
  virtual_network_name = azurerm_virtual_network.flowlog.name
  address_prefixes     = ["10.10.0.0/26"]
}

resource "azurerm_storage_account" "flowlog" {
  name                     = "stflowlogsdh${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.flowlog.name
  location                 = azurerm_resource_group.flowlog.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.flowlog.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_flowlog_vnet" {
  name                  = "link-blob-flowlog-vnet"
  resource_group_name   = azurerm_resource_group.flowlog.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.flowlog.id
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pep-stflowlogs-blob"
  location            = azurerm_resource_group.flowlog.location
  resource_group_name = azurerm_resource_group.flowlog.name
  subnet_id           = azurerm_subnet.pep.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-stflowlogs-blob"
    private_connection_resource_id = azurerm_storage_account.flowlog.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

# ---------------------------------------------------------------------------
# Dynamic cross-references — wiring external resources into the pattern
# ---------------------------------------------------------------------------

locals {
  # Merge peerings to external flowlog VNet into each hub VNet
  virtual_networks = {
    for k, v in var.virtual_networks : k => merge(v, {
      peerings = merge(coalesce(try(v.peerings, null), {}), {
        peer_to_flowlog = {
          name                               = "peer-${k}-to-flowlog"
          remote_virtual_network_resource_id = azurerm_virtual_network.flowlog.id
          create_reverse_peering             = true
          reverse_name                       = "peer-flowlog-to-${k}"
        }
      })
    })
  }

  # BYO DNS zone links — connect external blob DNS zone to each hub VNet
  byo_private_dns_zone_virtual_network_links = merge(var.byo_private_dns_zone_virtual_network_links, {
    link_blob_internet = {
      name                = "link-blob-to-internet"
      private_dns_zone_id = azurerm_private_dns_zone.blob.id
      virtual_network = {
        key = "vnet_internet"
      }
    }
    link_blob_intranet = {
      name                = "link-blob-to-intranet"
      private_dns_zone_id = azurerm_private_dns_zone.blob.id
      virtual_network = {
        key = "vnet_intranet"
      }
    }
  })

  # Flow log configuration referencing the external storage account
  # NOTE: The AVM network_watcher module performs a data lookup for an existing
  # Network Watcher. Azure auto-creates NetworkWatcher_<region> in
  # NetworkWatcherRG when VNets are deployed. To enable flow logs, first deploy
  # without flowlog_configuration, flowlog_configuration = null, then uncomment the block below after the
  # auto-created Network Watcher exists.
  #
  # The network_watcher_id, network_watcher_name, and resource_group_name fields
  # are optional — they default to the Azure standard NetworkWatcherRG /
  # NetworkWatcher_<location>.
  # flowlog_configuration = null
  flowlog_configuration = {
    network_watcher_id   = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_${var.location}"
    network_watcher_name = "NetworkWatcher_${var.location}"
    resource_group_name  = "NetworkWatcherRG"
    flow_logs = {
      fl_internet = {
        enabled = true
        name    = "fl-hub-internet"
        virtual_network = {
          key = "vnet_internet"
        }
        storage_account_id = azurerm_storage_account.flowlog.id
        retention_policy = {
          enabled = true
          days    = 90
        }
      }
      fl_intranet = {
        enabled = true
        name    = "fl-hub-intranet"
        virtual_network = {
          key = "vnet_intranet"
        }
        storage_account_id = azurerm_storage_account.flowlog.id
        retention_policy = {
          enabled = true
          days    = 90
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Hub Pattern Module
# ---------------------------------------------------------------------------

module "hub" {
  source = "../../"

  location                                   = var.location
  tags                                       = var.tags
  enable_telemetry                           = var.enable_telemetry
  resource_groups                            = var.resource_groups
  network_security_groups                    = var.network_security_groups
  nat_gateways                               = var.nat_gateways
  route_tables                               = var.route_tables
  virtual_networks                           = local.virtual_networks
  public_ips                                 = var.public_ips
  firewall_policies                          = var.firewall_policies
  firewalls                                  = var.firewalls
  virtual_network_gateways                   = var.virtual_network_gateways
  private_dns_zones                          = var.private_dns_zones
  byo_private_dns_zone_virtual_network_links = local.byo_private_dns_zone_virtual_network_links
  flowlog_configuration                      = local.flowlog_configuration

  depends_on = [azurerm_virtual_network.flowlog, azurerm_subnet.pep, azurerm_storage_account.flowlog, azurerm_private_dns_zone.blob]
}
