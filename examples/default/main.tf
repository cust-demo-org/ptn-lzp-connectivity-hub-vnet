module "hub" {
  source = "../../"

  location                 = var.location
  tags                     = var.tags
  enable_telemetry         = var.enable_telemetry
  resource_groups          = var.resource_groups
  network_security_groups  = var.network_security_groups
  nat_gateways             = var.nat_gateways
  route_tables             = var.route_tables
  virtual_networks         = var.virtual_networks
  public_ips               = var.public_ips
  firewall_policies        = var.firewall_policies
  firewalls                = var.firewalls
  virtual_network_gateways = var.virtual_network_gateways
  private_dns_zones        = var.private_dns_zones
  byo_private_dns_zones    = var.byo_private_dns_zones
  flowlog_configuration    = var.flowlog_configuration
}
