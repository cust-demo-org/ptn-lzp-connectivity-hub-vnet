# Data Model: PLZ Connectivity Hub VNet Pattern

**Date**: 2026-03-30 | **Branch**: `001-hub-vnet-pattern-spec`

---

## Resource Module Decomposition Amendment

**Date**: 2026-04-09

The pattern no longer uses the monolithic core AVM pattern module. All resources are now managed as individual AVM resource modules. The entity model is updated accordingly:

### Entities Restored (Previously Removed by Simplification)

- **Route Table** — Now an independent AVM resource module (`avm-res-network-routetable` v0.5.0). Flat global map variable `route_tables`.
- **Private DNS Zone** — Now an independent AVM resource module (`avm-res-network-privatednszone` v0.5.0). Flat global map variable `private_dns_zones` with embedded VNet links.
- **Private DNS Zone Virtual Network Link (BYO)** — BYO DNS zone VNet links via `byo_private_dns_zone_virtual_network_links`.

### Entities Added

- **Virtual Network** — AVM resource module (`avm-res-network-virtualnetwork` v0.17.1). Flat global map variable `virtual_networks`. Subnets reference NSGs, NAT gateways, and route tables by key.
- **Virtual Network Gateway** — Stub. Flat global map variable `virtual_network_gateways` (VPN + ExpressRoute).
- **Public IP** — Stub. Flat global map variable `public_ips`.
- **Firewall Policy** — Stub. Flat global map variable `firewall_policies`.
- **Firewall** — Stub. Flat global map variable `firewalls`.

### Entities Removed

- **Hub Virtual Network (Core Pattern)** — The monolithic `hub_virtual_networks` entity (E-002) is replaced by individual entities above. There is no longer a single composite entity that bundles VNet + firewall + bastion + gateways + DNS.

### Updated Entity Diagram

```
┌─────────────────────┐
│   Resource Group    │◄──── key: resource_group_key
│   (map variable)    │
└────────┬────────────┘
         │ contains
    ┌────┴────┬──────────┬──────────┬──────────┬──────────┐
    ▼         ▼          ▼          ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────┐
│ VNet   │ │ NSG    │ │NAT GW  │ │Route   │ │Firewall│ │Private DNS │
│(virtual│ │(nsg_key│ │(nat_gw │ │Table   │ │(fw_key)│ │Zone        │
│networks│ │global) │ │ key    │ │(rt_key)│ │        │ │(pdz_key)   │
│  map)  │ │        │ │global) │ │        │ │        │ │            │
└───┬────┘ └───┬────┘ └───┬────┘ └────────┘ └───┬────┘ └──────┬─────┘
    │subnets   │          │                      │             │
    │reference │          │                      │             │
    └──────────┴──────────┘               ┌──────┘             │
                                          ▼                    ▼
                                   ┌────────────┐      ┌──────────────┐
                                   │ FW Policy  │      │ DNS Zone     │
                                   │(fwp_key)   │      │ VNet Link    │
                                   └────────────┘      └──────────────┘
         ┌──────────────────┐
         │ Public IP        │      ┌──────────────┐
         │ (pip_key, global)│      │ VNet Gateway  │
         └──────────────────┘      │ (vng_key)     │
                                   └──────────────┘
         ┌──────────────┐
         │Network Watcher│◄──── flowlog_configuration
         │ (flow logs)   │
         └──────────────┘
```

### Key Resolution Pattern (Updated)

All cross-resource references use key-based lookups in `locals.tf`:

| Source Entity | Reference Field | Target Entity | Resolution |
|---------------|----------------|---------------|------------|
| VNet subnet | `network_security_group = { key }` | NSG | `local.nsg_resource_ids[key]` |
| VNet subnet | `route_table = { key }` | Route Table | `local.rt_resource_ids[key]` |
| VNet subnet | `nat_gateway = { key }` | NAT Gateway | `local.nat_gateway_resource_ids[key]` |
| NSG / NAT GW / Route Table / VNet / Firewall / etc. | `resource_group_key` | Resource Group | `local.resource_group_names[key]` |
| DNS Zone VNet Link | `virtual_network = { key }` | Virtual Network | `local.vnet_resource_ids[key]` |
| BYO DNS Zone Link | `virtual_network = { key }` | Virtual Network | `local.vnet_resource_ids[key]` |
| Flow Log | `virtual_network = { key }` | Virtual Network | `local.vnet_resource_ids[key]` |
| VNet Gateway | `virtual_network = { key }` | Virtual Network | `local.vnet_resource_ids[key]` |
| Firewall | `firewall_policy = { key }` | Firewall Policy | `local.firewall_policy_resource_ids[key]` |
| Role Assignment | `managed_identity_key` | Managed Identity | `local.managed_identity_principal_ids[key]` |

> **Note**: The original data model content and previous amendments below are preserved for historical context. Where they conflict with this amendment, this amendment takes precedence.

---

## Simplification Amendment

**Date**: 2026-03-30

The following entities have been **removed** from the pattern:
- **Spoke Peering** — handled by core pattern
- **Log Analytics Workspace** — not the pattern's responsibility; consumers provide LAW IDs via `diagnostic_settings`
- **Storage Account** — not the pattern's responsibility; flow logs take `storage_account_id` directly
- **Managed Identity** — not needed
- **Role Assignment** — not needed
- **Route Table** (supplementary) — handled by core pattern
- **Private DNS Zone** (supplementary) — handled by core pattern

**Remaining entities**: Resource Group, Hub Virtual Network, NSG, NAT Gateway, Network Watcher.

The entity diagram and descriptions below are preserved for historical context. Where they conflict with this amendment, the amendment takes precedence.

---

## Entity Relationship Overview

```
┌─────────────────────┐
│   Resource Group    │◄──── key: resource_group_key
│   (map variable)    │
└────────┬────────────┘
         │ contains
         ▼
┌─────────────────────┐     ┌──────────────────────┐
│ Hub Virtual Network │────►│  Core AVM Pattern    │
│ (hub_virtual_networks│     │  Module 0.16.14      │
│  map variable)      │     └──────────┬───────────┘
└────────┬────────────┘                │ creates
         │ subnets reference           ▼
         │                   ┌─────────────────────┐
         │                   │ Firewall, Bastion,   │
         │                   │ VPN GW, ER GW, DNS,  │
         │                   │ Route Tables, DDoS   │
         │                   └─────────────────────┘
         │
    ┌────┴──────────┬─────────────────┐
    ▼               ▼                 ▼
┌────────┐   ┌───────────┐   ┌──────────────┐
│  NSG   │   │NAT Gateway│   │ Spoke Peering│
│(nsg_key│   │(nat_gw_key│   │ (spoke_key)  │
│ global │   │  global   │   │  map var     │
│  map)  │   │  map)     │   └──────────────┘
└────┬───┘   └─────┬─────┘
     │              │
     └──────┬───────┘
            ▼
   ┌────────────────┐
   │ Diagnostic     │──────►┌──────────────────┐
   │ Settings       │       │ Log Analytics    │
   └────────────────┘       │ Workspace        │
                            │ (BYO or created) │
                            └──────────────────┘
                                     │
                            ┌────────┴────────┐
                            ▼                 ▼
                   ┌──────────────┐  ┌──────────────┐
                   │Network Watcher│  │Storage Account│
                   │ (flow logs)  │  │ (flow logs)  │
                   │              │  │ (BYO or      │
                   └──────────────┘  │  created)    │
                                     └──────────────┘
```

---

## Entities

### E-001: Resource Group

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | Yes | — | Resource group name |
| `location` | `string` | No | `var.location` | Azure region |
| `tags` | `map(string)` | No | `var.tags` | Tags merged with central tags |
| `lock` | `object({kind, name?})` | No | `null` | Resource lock |
| `role_assignments` | `map(object(...))` | No | `{}` | RBAC assignments |

**Key**: User-chosen string in `var.resource_groups` map.
**Relationships**: Referenced by `resource_group_key` from hub entries, NSGs, NAT GWs, storage accounts, etc.
**State**: Immutable after creation (name/location cannot change without recreation).

---

### E-002: Hub Virtual Network (Core Pattern)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `location` | `string` | Yes | — | Azure region for this hub |
| `enabled_resources` | `object(...)` | No | All `true` | Toggle firewall, bastion, gateways, DNS |
| `hub_virtual_network` | `object(...)` | No | `{}` | VNet config: address_space, subnets, DNS servers |
| `hub_virtual_network.subnets` | `map(object(...))` | No | `{}` | Subnets with NSG/NAT GW ID references |
| `firewall` | `object(...)` | No | `{}` | Firewall config: SKU, zones, IPs |
| `firewall_policy` | `object(...)` | No | `{}` | Policy: DNS proxy, intrusion detection, TLS |
| `bastion` | `object(...)` | No | `{}` | Bastion: SKU, features, public IP |
| `virtual_network_gateways` | `object(...)` | No | `{}` | VPN + ExpressRoute gateways |

**Key**: User-chosen string in `var.hub_virtual_networks` map.
**Relationships**: References `resource_group_key` → Resource Group; subnets reference NSGs and NAT GWs by resolved ID.
**State**: Supports incremental updates; `enabled_resources` flags toggle components.

---

### E-003: Network Security Group (Supplementary)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | Yes | — | NSG name |
| `resource_group_key` | `string` | Yes | — | Key into `var.resource_groups` |
| `location` | `string` | No | `var.location` | Azure region |
| `security_rules` | `map(object(...))` | No | `{}` | NSG rules |
| `diagnostic_settings` | `map(object(...))` | No | `{}` | Diagnostics to LAW |
| `lock` | `object(...)` | No | `null` | Resource lock |
| `role_assignments` | `map(object(...))` | No | `{}` | RBAC assignments |
| `tags` | `map(string)` | No | `var.tags` | Tags |

**Key**: `nsg_key` — globally unique in `var.network_security_groups` flat map.
**Relationships**: Referenced by hub subnets via `network_security_group = { id = local.nsg_resource_ids[nsg_key] }`.
**Validation**: Pattern MUST fail at plan time if a referenced `nsg_key` does not exist.

---

### E-004: NAT Gateway (Supplementary — TO ADD)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | Yes | — | NAT Gateway name |
| `resource_group_key` | `string` | Yes | — | Key into `var.resource_groups` |
| `location` | `string` | No | `var.location` | Azure region |
| `sku_name` | `string` | No | `"Standard"` | SKU |
| `idle_timeout_in_minutes` | `number` | No | `4` | Idle timeout |
| `zones` | `list(string)` | No | `null` | Availability zones |
| `public_ip_configuration` | `object(...)` | No | `{}` | Public IP settings |
| `diagnostic_settings` | `map(object(...))` | No | `{}` | Diagnostics to LAW |
| `lock` | `object(...)` | No | `null` | Resource lock |
| `role_assignments` | `map(object(...))` | No | `{}` | RBAC assignments |
| `tags` | `map(string)` | No | `var.tags` | Tags |

**Key**: `nat_gateway_key` — globally unique in `var.nat_gateways` flat map.
**Relationships**: Referenced by hub subnets via `nat_gateway = { key = "<nat_gateway_key>" }`, resolved to `{ id = local.nat_gateway_resource_ids[key] }`.
**Validation**: Pattern MUST fail at plan time if a referenced `nat_gateway.key` does not exist.

---

### E-005: Spoke VNet Peering (TO ADD)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `spoke_vnet_resource_id` | `string` | Yes | — | Full resource ID of existing spoke VNet |
| `hub_key` | `string` | Yes | — | Key into `var.hub_virtual_networks` identifying the hub |
| `allow_forwarded_traffic` | `bool` | No | `true` | Allow forwarded traffic |
| `allow_gateway_transit` | `bool` | No | `true` | Allow gateway transit (hub side) |
| `use_remote_gateways` | `bool` | No | `true` | Use remote gateways (spoke side) |
| `allow_virtual_network_access` | `bool` | No | `true` | Allow VNet access |

**Key**: `spoke_key` — unique within peering variable.
**Relationships**: Creates TWO resources per entry: `azurerm_virtual_network_peering` hub→spoke and spoke→hub.
**State**: Removing an entry destroys only that spoke's peering; no cascade.

---

### E-006: Log Analytics Workspace (Supplementary)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | Conditional | — | LAW name (if creating) |
| `resource_group_key` | `string` | Conditional | — | Key into `var.resource_groups` |
| `location` | `string` | No | `var.location` | Azure region |
| `retention_in_days` | `number` | No | `30` | Log retention (spec: 30 days default) |
| `sku` | `string` | No | `"PerGB2018"` | SKU |

**Key**: Referenced via `byo_log_analytics_workspace` (BYO) or the wrapper-created instance.
**Relationships**: Consumed by all diagnostic settings; passed to core pattern for firewall insights.
**BYO fallback**: When `byo_log_analytics_workspace.resource_id` is supplied, no new workspace is created.

---

### E-007: Storage Account (Supplementary — Flow Logs)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | Yes | — | Storage account name (3–24 chars, globally unique) |
| `resource_group_key` | `string` | Yes | — | Key into `var.resource_groups` |
| `location` | `string` | No | `var.location` | Azure region |
| `account_tier` | `string` | No | `"Standard"` | Tier |
| `account_replication_type` | `string` | No | `"ZRS"` | Replication |
| `public_network_access_enabled` | `bool` | No | `false` | Secure by default |
| `min_tls_version` | `string` | No | `"TLS1_2"` | Minimum TLS |

**Key**: `storage_account_key` in `var.storage_accounts` map.
**Relationships**: Referenced by flow log configuration via `storage_account.key`.
**BYO fallback**: Flow log entries can supply `storage_account.resource_id` directly.

---

### E-008: Network Watcher / Flow Logs (Supplementary)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `network_watcher_id` | `string` | No | Auto-created | Existing watcher ID |
| `location` | `string` | No | `var.location` | Azure region |
| `flow_logs` | `map(object(...))` | No | `null` | Flow log entries |
| `flow_logs[*].virtual_network` | `object({ key, resource_id })` | Yes (per entry) | — | Hub VNet reference for flow logging |
| `flow_logs[*].storage_account` | `object(...)` | Yes (per entry) | — | Storage target (key or resource_id) |
| `flow_logs[*].traffic_analytics` | `object(...)` | No | `null` | Traffic analytics config |

**Key**: Singleton configuration object (`var.flowlog_configuration`).
**Relationships**: References VNet by key, storage account by key, LAW for traffic analytics.

---

## Key Resolution Pattern

All cross-resource wiring uses the same pattern:

```hcl
locals {
  # Build map: key → resource ID
  nsg_resource_ids = {
    for key, nsg in module.network_security_group : key => nsg.resource_id
  }
  nat_gateway_resource_ids = {
    for key, ng in module.nat_gateway : key => ng.resource_id
  }
  # ... same for storage_account, managed_identity, etc.
}

# Usage in core pattern:
module "hub_and_spoke_vnet_pattern" {
  hub_virtual_networks = {
    for key, hub in var.hub_virtual_networks : key => merge(hub, {
      hub_virtual_network = merge(hub.hub_virtual_network, {
        subnets = {
          for sk, subnet in hub.hub_virtual_network.subnets : sk => merge(subnet, {
            network_security_group = subnet.network_security_group != null && subnet.network_security_group.key != null ? {
              id = local.nsg_resource_ids[subnet.network_security_group.key]
            } : null
            nat_gateway = subnet.nat_gateway != null && subnet.nat_gateway.key != null ? {
              id = local.nat_gateway_resource_ids[subnet.nat_gateway.key]
            } : null
          })
        }
      })
    })
  }
}
```

---

## State Transitions

### Module Lifecycle

```
1. Resource Groups created first (no dependencies)
2. Supplementary modules (NSG, NAT GW, LAW, Storage) created in parallel
3. Core pattern module created (depends on NSG/NAT GW IDs for subnet wiring)
4. VNet peering created (depends on core pattern VNet outputs)
5. Network Watcher + flow logs created (depends on VNet IDs + storage account IDs)
```

### BYO Decision Flow

```
IF byo_log_analytics_workspace.resource_id != null:
  → Use BYO LAW ID
  → Skip LAW module creation
ELSE:
  → Create LAW via supplementary module
  → Use module output ID

IF flow_log.storage_account.resource_id != null:
  → Use BYO storage ID
ELIF flow_log.storage_account.key != null:
  → Use local.storage_account_resource_ids[key]
```
