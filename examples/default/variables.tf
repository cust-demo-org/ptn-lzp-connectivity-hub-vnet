variable "location" {
  type        = string
  description = "The default Azure region for all resources. Refer to the main pattern module variable descriptions for complete details."
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = "Controls AVM telemetry collection across all modules. Disabled by default in examples. Refer to the main pattern module variable descriptions for complete details."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Base tags applied to all resources. Merged with any resource-level tags. Refer to the main pattern module variable descriptions for complete details."
}

variable "resource_groups" {
  type        = any
  default     = {}
  description = "Map of resource groups to create. Other resources reference these by key. Refer to the main pattern module variable descriptions for complete details."
}

variable "network_security_groups" {
  type        = any
  default     = {}
  description = "Map of Network Security Groups to create. Referenced by VNet subnets via network_security_group_key. Refer to the main pattern module variable descriptions for complete details."
}

variable "route_tables" {
  type        = any
  default     = {}
  description = "Map of route tables to create. Referenced by VNet subnets via route_table_key. Refer to the main pattern module variable descriptions for complete details."
}

variable "nat_gateways" {
  type        = any
  default     = {}
  description = "Map of NAT Gateways to create. Referenced by VNet subnets via nat_gateway_key. Refer to the main pattern module variable descriptions for complete details."
}

variable "virtual_networks" {
  type        = any
  default     = {}
  description = "Map of virtual networks to create with subnets, peerings, and DDoS configuration. Refer to the main pattern module variable descriptions for complete details."
}

variable "virtual_network_gateways" {
  type        = any
  default     = {}
  description = "Map of VPN/ExpressRoute gateways to create. Refer to the main pattern module variable descriptions for complete details."
}

variable "public_ips" {
  type        = any
  default     = {}
  description = "Map of public IP addresses to create. Refer to the main pattern module variable descriptions for complete details."
}

variable "firewall_policies" {
  type        = any
  default     = {}
  description = "Map of Azure Firewall Policies to create. Referenced by firewalls via firewall_policy = { key }. Refer to the main pattern module variable descriptions for complete details."
}

variable "firewalls" {
  type        = any
  default     = {}
  description = "Map of Azure Firewalls to create. Refer to the main pattern module variable descriptions for complete details."
}

variable "private_dns_zones" {
  type        = any
  default     = {}
  description = "Map of private DNS zones to create. Refer to the main pattern module variable descriptions for complete details."
}

variable "byo_private_dns_zone_virtual_network_links" {
  type        = any
  default     = {}
  description = "Map of BYO private DNS zone VNet links. Refer to the main pattern module variable descriptions for complete details."
}

variable "flowlog_configuration" {
  type        = any
  default     = null
  description = "Network Watcher flow log configuration. Null disables flow logs. Refer to the main pattern module variable descriptions for complete details."
}
