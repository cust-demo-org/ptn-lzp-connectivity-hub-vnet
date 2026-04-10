# Variable Interface Contracts: PLZ Connectivity Hub VNet Pattern

**Date**: 2026-03-30 | **Branch**: `001-hub-vnet-pattern-spec`

This document defines the public variable and output contracts for consumers of the pattern.

---

## Resource Module Decomposition Amendment

**Date**: 2026-04-09

### Removed Variables (Core Pattern Passthrough)

The following variables are removed — they were specific to the monolithic core AVM pattern module:
- `hub_virtual_networks` — Replaced by individual resource variables
- `hub_and_spoke_networks_settings` — DDoS configured directly on VNet entries
- `default_naming_convention` — Consumers name resources explicitly
- `default_naming_convention_sequence` — No longer applicable
- `timeouts` (root-level) — Per-resource in individual variables

### Restored Variables

The following variables are restored (were removed by Simplification Amendment because the core pattern handled them):
- `route_tables` — Flat global map for route table definitions
- `private_dns_zones` — Flat global map for private DNS zone definitions with VNet links
- `byo_private_dns_zone_virtual_network_links` — Flat global map for BYO DNS zone VNet link definitions

### New Variables

| Variable | Type | Required | Default | Flat Map? | Module |
|----------|------|----------|---------|-----------|--------|
| `virtual_networks` | `map(object({...}))` | No | `{}` | Yes (global) | `avm-res-network-virtualnetwork` v0.17.1 |
| `virtual_network_gateways` | `map(object({...}))` | No | `{}` | Yes (global) | VNet gateway sub-module v0.16.14 |
| `public_ips` | `map(object({...}))` | No | `{}` | Yes (global) | `avm-res-network-publicipaddress` v0.2.1 |
| `firewall_policies` | `map(object({...}))` | No | `{}` | Yes (global) | `avm-res-network-firewallpolicy` v0.3.4 |
| `firewalls` | `map(object({...}))` | No | `{}` | Yes (global) | `avm-res-network-azurefirewall` v0.4.0 |

### Current Complete Variable Inventory

| Variable | Type | Module | Status |
|----------|------|--------|--------|
| `location` | `string` | Central | Implemented |
| `enable_telemetry` | `bool` | Central | Implemented |
| `tags` | `map(string)` | Central | Implemented |
| `resource_groups` | `map(object({...}))` | `avm-res-resources-resourcegroup` | Implemented |
| `network_security_groups` | `map(object({...}))` | `avm-res-network-networksecuritygroup` | Implemented |
| `route_tables` | `map(object({...}))` | `avm-res-network-routetable` | Implemented |
| `nat_gateways` | `map(object({...}))` | `avm-res-network-natgateway` | Implemented |
| `virtual_networks` | `map(object({...}))` | `avm-res-network-virtualnetwork` | Implemented |
| `virtual_network_gateways` | `map(object({...}))` | VNet gateway sub-module | Implemented |
| `public_ips` | `map(object({...}))` | `avm-res-network-publicipaddress` | Implemented |
| `firewall_policies` | `map(object({...}))` | `avm-res-network-firewallpolicy` | Implemented |
| `firewalls` | `map(object({...}))` | `avm-res-network-azurefirewall` | Implemented |
| `private_dns_zones` | `map(object({...}))` | `avm-res-network-privatednszone` | Implemented |
| `byo_private_dns_zone_virtual_network_links` | `map(object({...}))` | DNS zone link sub-module | Implemented |
| `flowlog_configuration` | `object({...})` | `avm-res-network-networkwatcher` | Implemented |

### Cross-Reference Convention: Key/ID Pattern

All cross-resource references use a consistent object pattern:

**Single reference** (e.g., firewall → public IP for ip_configuration):
```hcl
public_ip_address = {
  key = "pip_fw_internet"   # key into pattern-managed `public_ips` variable
  id  = null                # OR direct resource ID for externally-managed resources
}
```

**Multiple references** (e.g., NAT gateway → public IPs):
```hcl
public_ip_addresses = {
  keys = ["pip_natgw"]      # set of keys into pattern-managed `public_ips` variable
  ids  = []                 # set of direct resource IDs for externally-managed resources
}
```

This pattern applies consistently:
- `firewall.firewall_policy` → `{ key, resource_id }`
- `firewall.ip_configuration[].public_ip_address` → `{ key, resource_id }`
- `firewall.ip_configuration[].subnet` → `{ vnet_key, subnet_key, resource_id }`
- `firewall.management_ip_configuration.public_ip_address` → `{ key, resource_id }`
- `firewall.management_ip_configuration.subnet` → `{ vnet_key, subnet_key, resource_id }`
- `nat_gateway.public_ip_addresses` → `{ keys, ids }`
- `virtual_network.subnets[].network_security_group` → `{ key, resource_id }`
- `virtual_network.subnets[].route_table` → `{ key, resource_id }`
- `virtual_network.subnets[].nat_gateway` → `{ key, resource_id }`
- `virtual_network_gateway.virtual_network` → `{ key, resource_id }`
- `virtual_network_gateway.gateway_subnet` → `{ vnet_key, subnet_key, resource_id }`
- `virtual_network_gateway.ip_configurations[].public_ip_address` → `{ key, resource_id }`
- `private_dns_zones.virtual_network_links[].virtual_network` → `{ key, resource_id }`
- `byo_private_dns_zone_virtual_network_links[].virtual_network` → `{ key, resource_id }`
- `flowlog_configuration.flow_logs[].virtual_network` → `{ key, resource_id }`

### Updated Output Contracts

| Output | Type | Source | Description |
|--------|------|--------|-------------|
| `resource_group_ids` | `map(string)` | `module.resource_group` | Map of key → resource group ID |
| `resource_group_names` | `map(string)` | `module.resource_group` | Map of key → resource group name |
| `nsg_resource_ids` | `map(string)` | `module.network_security_group` | Map of key → NSG resource ID |
| `nat_gateway_resource_ids` | `map(string)` | `module.nat_gateway` | Map of key → NAT GW resource ID |
| `virtual_network_ids` | `map(string)` | `module.virtual_network` | Map of key → VNet resource ID |
| `route_table_ids` | `map(string)` | `module.route_table` | Map of key → route table resource ID |
| `firewall_ids` | `map(string)` | `module.firewall` | Map of key → firewall resource ID |
| `firewall_policy_ids` | `map(string)` | `module.firewall_policy` | Map of key → firewall policy resource ID |
| `public_ip_ids` | `map(string)` | `module.public_ip` | Map of key → public IP resource ID |
| `virtual_network_gateway_ids` | `map(string)` | `module.virtual_network_gateway` | Map of key → VNet gateway resource ID |
| `private_dns_zone_ids` | `map(string)` | `module.private_dns_zone` | Map of key → DNS zone resource ID |
| `network_watcher_id` | `string` | `module.network_watcher` | Network Watcher resource ID |

> **Note**: The original contract content and previous amendments below are preserved for historical context. Where they conflict with this amendment, this amendment takes precedence.

---

## Simplification Amendment

**Date**: 2026-03-30

### Removed Input Variables

The following variables have been removed from the pattern:
- `byo_log_analytics_workspace`
- `log_analytics_workspace_configuration`
- `route_tables`
- `private_dns_zones`
- `byo_private_dns_zone_virtual_network_links`
- `managed_identities`
- `spoke_virtual_networks`
- `storage_accounts`
- `role_assignments`

### Removed Outputs

- `log_analytics_workspace_id`
- `storage_account_resource_ids`
- `managed_identity_principal_ids`
- `private_dns_zone_resource_ids`
- `spoke_peering_ids`

### Simplified Variables

- `network_security_groups` / `nat_gateways`: `diagnostic_settings` and `role_assignments` are passed through directly (no `use_default_log_analytics` or `managed_identity_key`).
- `flowlog_configuration`: Flow logs now take `storage_account_id` (string) directly instead of resolving via `storage_account.key`.

### Variable Description Standards

All root-level variable descriptions follow AVM module documentation conventions:
- Every nested attribute is documented with `(Required)` / `(Optional)` markers
- Nested objects show their sub-attributes indented under the parent
- Default values are documented inline where applicable
- Pattern notes explain wrapper-specific behaviors (e.g., key resolution, tag merging, location defaulting)
- Complex passthrough objects (e.g., `virtual_network_gateways.express_route`, `virtual_network_gateways.vpn`, `private_dns_zones`, `private_dns_resolver`) have all nested attributes fully documented inline — no external documentation references

### Current Supplementary Variables

| Variable | Type | Required | Default | Flat Map? |
|----------|------|----------|---------|-----------|
| `network_security_groups` | `map(object({...}))` | No | `{}` | Yes (global) |
| `nat_gateways` | `map(object({...}))` | No | `{}` | Yes (global) |

### Current Output Contracts

| Output | Type | Description |
|--------|------|-------------|
| `hub_virtual_network_ids` | `map(string)` | Map of hub key -> VNet resource ID |
| `hub_virtual_network_names` | `map(string)` | Map of hub key -> VNet name |
| `firewall_private_ip_addresses` | `map(string)` | Map of hub key -> firewall private IP |
| `firewall_resource_names` | `map(string)` | Map of hub key -> firewall resource name |
| `bastion_host_dns_names` | `map(string)` | Map of hub key -> bastion DNS name |
| `route_tables_firewall` | `map(object)` | Firewall route table details |
| `route_tables_user_subnets` | `map(object)` | User subnet route table details |
| `resource_group_ids` | `map(string)` | Map of key -> resource group ID |
| `resource_group_names` | `map(string)` | Map of key -> resource group name |
| `nsg_resource_ids` | `map(string)` | Map of nsg_key -> NSG resource ID |
| `nat_gateway_resource_ids` | `map(string)` | Map of nat_gateway_key -> NAT GW resource ID |
| `network_watcher_id` | `string` | Network watcher resource ID |

> **Note**: The original contract content below is preserved for historical context. Where it conflicts with this amendment, the amendment takes precedence.

---

## Input Variable Contracts

> **Passthrough Principle**: Every parameter exposed by each AVM module (core pattern and supplementary) MUST be passthrough from root-level variables / `terraform.tfvars`. No AVM module parameter may be hardcoded in `main.tf` unless it is a computed/derived value (resolved resource ID, merged tags, defaulted location). This ensures consumers can configure everything through `terraform.tfvars` without modifying module source code (constitution principle III).

### Central Variables (Root-Level)

| Variable | Type | Required | Default | Purpose |
|----------|------|----------|---------|---------|
| `location` | `string` | Yes | — | Default Azure region for all resources |
| `enable_telemetry` | `bool` | No | `true` | AVM telemetry opt-in, propagated to all modules |
| `tags` | `map(string)` | No | `{}` | Base tags propagated to all resources |

### Resource Groups

| Variable | Type | Required | Default |
|----------|------|----------|---------|
| `resource_groups` | `map(object({name, location?, tags?, lock?, role_assignments?}))` | Yes | — |

**Contract**: At least one resource group must be defined. Other resources reference by map key.

### Core Pattern Passthrough

| Variable | Type | Required | Default |
|----------|------|----------|---------|
| `hub_virtual_networks` | `map(object({...}))` | Yes | — |
| `hub_and_spoke_networks_settings` | `object({...})` | No | `{}` |
| `default_naming_convention` | `object({...})` | No | Core pattern defaults |
| `default_naming_convention_sequence` | `object({starting_number, padding_format})` | No | `{starting_number=1, padding_format="%03d"}` |
| `timeouts` | `object({create?, read?, update?, delete?})` | No | `{}` |

**Contract**: `hub_virtual_networks` keys are user-chosen. Subnets within hubs may reference `network_security_group = { key }`, `route_table = { key }`, and `nat_gateway = { key }` — the wrapper resolves these to resource IDs before passing to the core pattern. Similarly, DNS zone links use `virtual_network = { key }` and firewalls use `firewall_policy = { key }`.

### Supplementary Module Variables

| Variable | Type | Required | Default | Flat Map? |
|----------|------|----------|---------|-----------|
| `network_security_groups` | `map(object({...}))` | No | `{}` | Yes (global) |
| `nat_gateways` | `map(object({...}))` | No | `{}` | Yes (global) |
| `storage_accounts` | `map(object({...}))` | No | `{}` | Yes (global) |
| `managed_identities` | `map(object({...}))` | No | `{}` | Yes (global) |
| `route_tables` | `map(object({...}))` | No | `{}` | Yes (global) |
| `private_dns_zones` | `map(object({...}))` | No | `{}` | Yes (global) |
| `role_assignments` | `map(object({...}))` | No | `{}` | Yes (global) |

### BYO Resources

| Variable | Type | Required | Default |
|----------|------|----------|---------|
| `byo_log_analytics_workspace` | `object({resource_id})` | No | `null` |
| `log_analytics_workspace_configuration` | `object({name, resource_group_key, location?, retention_in_days?, ...})` | No | `null` |
| `byo_private_dns_zone_virtual_network_links` | `map(object({...}))` | No | `{}` |

**Contract**: BYO resource ID takes precedence. If BYO is null and configuration is provided, wrapper creates the resource.

### Observability

| Variable | Type | Required | Default |
|----------|------|----------|---------|
| `flowlog_configuration` | `object({...})` | No | `null` |

---

## Output Contracts

### Core Pattern Outputs (Passthrough)

| Output | Type | Description |
|--------|------|-------------|
| `hub_virtual_network_ids` | `map(string)` | Map of hub key → VNet resource ID |
| `hub_virtual_network_names` | `map(string)` | Map of hub key → VNet name |
| `firewall_private_ip_addresses` | `map(string)` | Map of hub key → firewall private IP |
| `firewall_resource_names` | `map(string)` | Map of hub key → firewall resource name |
| `bastion_host_dns_names` | `map(string)` | Map of hub key → bastion DNS name |
| `route_tables_firewall` | `map(object)` | Firewall route table details |
| `route_tables_user_subnets` | `map(object)` | User subnet route table details |
| `private_dns_zone_resource_ids` | `map(string)` | Private DNS zone resource IDs |

### Supplementary Resource Outputs

| Output | Type | Description |
|--------|------|-------------|
| `resource_group_ids` | `map(string)` | Map of key → resource group ID |
| `resource_group_names` | `map(string)` | Map of key → resource group name |
| `nsg_resource_ids` | `map(string)` | Map of nsg_key → NSG resource ID |
| `nat_gateway_resource_ids` | `map(string)` | Map of nat_gateway_key → NAT GW resource ID |
| `log_analytics_workspace_id` | `string` | LAW resource ID (BYO or created) |
| `storage_account_resource_ids` | `map(string)` | Map of storage_account_key → storage account ID |
| `managed_identity_principal_ids` | `map(string)` | Map of key → managed identity principal ID |
| `network_watcher_id` | `string` | Network watcher resource ID |

### Peering Outputs

| Output | Type | Description |
|--------|------|-------------|
| `spoke_peering_ids` | `map(object({hub_to_spoke_id, spoke_to_hub_id}))` | Map of spoke_key → peering resource IDs |

---

## Cross-Pattern Integration Points

### For Spoke Landing Zone Patterns (Downstream Consumers)

Spoke patterns consume the following outputs to establish connectivity:

1. **Hub VNet ID** → for peering (if not using this pattern's built-in peering)
2. **Firewall private IP** → for route table next-hop in spoke subnets
3. **Private DNS zone IDs** → for VNet linking in spokes
4. **Bastion DNS name** → for secure VM access from spokes
5. **LAW resource ID** → for diagnostic settings in spoke resources

### For CI/CD Pipelines (Consumers)

Pipelines consume the pattern by:
1. Providing a `terraform.tfvars` file with all inputs
2. Running `terraform init`, `terraform plan`, `terraform apply`
3. Reading outputs for downstream automation

No pipeline-specific contracts are needed — the pattern is consumed purely through its Terraform interface.
