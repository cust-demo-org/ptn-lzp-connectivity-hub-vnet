# Research: PLZ Connectivity Hub VNet Pattern

**Date**: 2026-03-30 | **Branch**: `001-hub-vnet-pattern-spec`

---

## Resource Module Decomposition Amendment

**Date**: 2026-04-09

### R-009: Resource Module Decomposition Decision

**Decision**: Replace the monolithic AVM pattern module `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` (v0.16.14) with individual AVM resource modules.

**Rationale**: The core pattern module bundles VNet, firewall, bastion, gateways, DNS, route tables, and DDoS into a single opinionated module. This was found to be **restrictive** for the following reasons:
1. **Lifecycle coupling** — Updating one resource (e.g., firewall policy rules) requires re-planning the entire hub topology
2. **Version lag** — The pattern module pins internal resource module versions; upgrading requires waiting for a new pattern release
3. **Limited extensibility** — The pattern module does not expose every parameter of its internal resource modules
4. **Key resolution gaps** — Complex cross-resource wiring (e.g., route tables to subnets, DNS zone links to VNets) requires wrapper-level logic that conflicts with the pattern module's internal resource management

By decomposing to individual AVM resource modules, the wrapper gains:
- Independent resource lifecycle management
- Direct access to every AVM resource module parameter (full passthrough)
- Ability to pin and upgrade each module version independently
- Full control over cross-resource wiring logic in `locals.tf`

**Impact on R-001**: R-001 is **superseded** — the core AVM pattern module is no longer used as the primary engine. Individual AVM resource modules collectively replace it.

**Impact on R-003**: R-003 is **superseded** — VNet peering is now handled via the `avm-res-network-virtualnetwork` module's built-in peering support, not standalone `azurerm_virtual_network_peering` resources.

**Impact on Simplification Amendment**: Route tables, private DNS zones, and DNS zone links that were removed by the Simplification Amendment are **restored** as independent AVM resource modules.

### Updated Module Inventory

| Module | Registry Source | Version | Purpose |
|--------|----------------|---------|---------|
| Resource Group | `Azure/avm-res-resources-resourcegroup/azurerm` | 0.2.2 | Create resource groups |
| Network Security Group | `Azure/avm-res-network-networksecuritygroup/azurerm` | 0.5.1 | Create NSGs with security rules and diagnostics |
| Route Table | `Azure/avm-res-network-routetable/azurerm` | 0.5.0 | Create route tables with custom routes |
| NAT Gateway | `Azure/avm-res-network-natgateway/azurerm` | 0.3.2 | Create NAT gateways with public IPs |
| Virtual Network | `Azure/avm-res-network-virtualnetwork/azurerm` | 0.17.1 | Create VNets with subnets, peerings, DDoS |
| Virtual Network Gateway | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm//modules/virtual-network-gateway` | 0.16.14 | Create VPN/ExpressRoute gateways (sub-module from pattern) |
| Public IP | `Azure/avm-res-network-publicipaddress/azurerm` | 0.2.1 | Create standalone public IPs |
| Firewall Policy | `Azure/avm-res-network-firewallpolicy/azurerm` | 0.3.4 | Create firewall policies (DNS proxy, IDPS, TLS) |
| Firewall | `Azure/avm-res-network-azurefirewall/azurerm` | 0.4.0 | Create Azure Firewalls |
| Private DNS Zone | `Azure/avm-res-network-privatednszone/azurerm` | 0.5.0 | Create private DNS zones with VNet links |
| Private DNS Zone Link | `Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link` | 0.5.0 | Link BYO DNS zones to VNets |
| Network Watcher | `Azure/avm-res-network-networkwatcher/azurerm` | 0.3.2 | Create Network Watcher with flow logs |

**Alternatives Considered**: Continued use of the pattern module with workarounds — rejected due to fundamental architectural constraints described above.

> **Note**: The original research content and previous amendments below are preserved for historical context. Where they conflict with this amendment, this amendment takes precedence.

---

## Simplification Amendment

**Date**: 2026-03-30

Research findings R-003 (VNet peering), R-010 (route_table, private_dns_zone, managed_identity, role_assignment justification) are now **obsolete** — these modules have been removed from the pattern. See spec.md Simplification Amendment for rationale.

---

## R-001: Core AVM Pattern Module Interface & Latest Version

**Decision**: Use `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` version `0.16.14` (latest as of 2026-03-30).

**Rationale**: The core pattern module is the single source of truth for hub VNet infrastructure per the constitution. Version 0.16.14 is the latest release on the Terraform Registry.

**Key Inputs**:
- `hub_virtual_networks` — map-based, supports multi-hub. Each hub defines `enabled_resources`, `hub_virtual_network`, `firewall`, `firewall_policy`, `bastion`, `virtual_network_gateways`, `private_dns_zones`, `private_dns_resolver`.
- `hub_and_spoke_networks_settings` — shared settings (DDoS protection plan, `enabled_resources.ddos_protection_plan`).
- `default_naming_convention` — naming templates with `${location}` and `${sequence}` placeholders.
- `default_naming_convention_sequence` — starting number + padding format.
- `enable_telemetry`, `tags`, `timeouts` — global controls.

**Key Outputs**:
- `firewall_private_ip_addresses` — private IPs of firewalls
- `firewall_resource_names` — firewall resource names
- `name` — VNet names
- `resource_id` — VNet resource IDs
- `virtual_network_resource_ids` — VNet resource IDs
- `route_tables_firewall` / `route_tables_user_subnets` — route tables
- `bastion_host_dns_names` — bastion DNS names
- `private_dns_zone_resource_ids` — private DNS zone IDs

**Subnet NSG/NAT Gateway wiring**: Hub subnets accept `network_security_group = { id = string }` and `nat_gateway = { id = string }`. The wrapper resolves keys to IDs before passing to the core pattern.

**Alternatives Considered**: None — the constitution mandates the core pattern as primary engine.

---

## R-002: Latest AVM Module Versions (Supplementary & Supporting)

**Decision**: Pin all AVM modules to the following latest versions.

| Module | Registry Source | Current in Code | Latest | Update Needed? |
|--------|----------------|-----------------|--------|----------------|
| Core pattern | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` | N/A (TODO placeholder) | **0.16.14** | Add |
| Resource Group | `Azure/avm-res-resources-resourcegroup/azurerm` | 0.2.2 | **0.2.2** | No |
| Log Analytics Workspace | `Azure/avm-res-operationalinsights-workspace/azurerm` | 0.5.1 | **0.5.1** | No |
| Network Security Group | `Azure/avm-res-network-networksecuritygroup/azurerm` | 0.5.1 | **0.5.1** | No |
| Route Table | `Azure/avm-res-network-routetable/azurerm` | 0.5.0 | **0.5.0** | No |
| Private DNS Zone | `Azure/avm-res-network-privatednszone/azurerm` | 0.5.0 | **0.5.0** | No |
| Managed Identity | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | 0.4.0 | **0.5.0** | **Yes** (0.4.0 → 0.5.0) |
| Storage Account | `Azure/avm-res-storage-storageaccount/azurerm` | 0.6.7 | **0.6.8** | **Yes** (0.6.7 → 0.6.8) |
| Role Assignment | `Azure/avm-res-authorization-roleassignment/azurerm` | 0.3.0 | **0.3.0** | No |
| Network Watcher | `Azure/avm-res-network-networkwatcher/azurerm` | 0.3.2 | **0.3.2** | No |
| NAT Gateway | `Azure/avm-res-network-natgateway/azurerm` | N/A (missing) | **0.3.2** | **Add** |
| Virtual Network (peering) | `Azure/avm-res-network-virtualnetwork/azurerm` | N/A (missing) | **0.17.1** | **Evaluate** |

**Rationale**: Constitution principle II mandates pinned versions updated through reviewed PRs. Latest versions checked via Terraform Registry MCP server on 2026-03-30.

**Alternatives Considered**: N/A — AVM modules are mandated by the constitution.

---

## R-003: Bidirectional VNet Peering Implementation

**Decision**: Use `azurerm_virtual_network_peering` resource blocks (hub→spoke and spoke→hub) rather than the AVM VNet module's peering submodule.

**Rationale**: The core pattern manages mesh peering between hubs internally. For external hub-to-spoke peering, the simplest approach is two `azurerm_virtual_network_peering` resources per spoke entry. The AVM VNet module (`avm-res-network-virtualnetwork`) is a full VNet module — using it solely for peering would be over-engineering. Since no standalone AVM peering resource module exists, using `azurerm_virtual_network_peering` directly is justified per constitution principle II (custom azurerm resources permitted when no AVM module exists).

**Alternatives Considered**:
- AVM VNet module peering submodule — rejected because it requires the full VNet module instantiation and is designed for peering within the VNet module's lifecycle, not for external peering to pre-existing spoke VNets.
- Core pattern's built-in peering — only supports hub-to-hub mesh peering, not hub-to-spoke.

---

## R-004: NAT Gateway Module (Missing from Code)

**Decision**: Add `Azure/avm-res-network-natgateway/azurerm` version `0.3.2` as a supplementary module.

**Rationale**: The spec (FR-004) requires NAT Gateway provisioning. The core pattern accepts NAT Gateway IDs on subnets but does not create them. The module is currently missing from the code. Must be wired using the same flat global map pattern as NSGs (`nat_gateways` variable keyed by `nat_gateway_key`).

**Alternatives Considered**: Using `azurerm_nat_gateway` directly — rejected because an AVM module exists and the constitution mandates AVM-first.

---

## R-005: Examples Directory Structure (AVM Convention)

**Decision**: Follow standard AVM example conventions with self-contained, zero-input, deployable examples.

**Rationale**: The user explicitly requested AVM-style examples. AVM modules use a standard structure documented below.

**AVM Example Conventions**:

### Directory layout
```
examples/
├── .terraform-docs.yml          # Shared terraform-docs config for all examples
├── README.md                    # Boilerplate instructions
├── default/                     # REQUIRED — minimal viable deployment
│   ├── main.tf                  # terraform{} + provider{} + module call
│   ├── outputs.tf               # At least one output
│   ├── _header.md               # Short title + one-line description
│   ├── _footer.md               # Microsoft data collection notice
│   └── README.md                # Auto-generated by terraform-docs
└── <feature-name>/              # Additional feature-specific examples
    ├── main.tf
    ├── outputs.tf
    ├── _header.md
    ├── _footer.md
    └── README.md
```

### Key conventions
1. **No separate `terraform.tf`** — The `terraform {}` block (required_version, required_providers) and `provider` block go in `main.tf`.
2. **Module source is `../../`** (relative path to repo root), with a commented-out registry source hint.
3. **Zero required input variables** — all values generated via `random_*` resources, `Azure/naming/azurerm`, and `Azure/regions/azurerm` modules.
4. **Each example creates its own resource group** — self-contained and destroyable.
5. **README.md is auto-generated** by `terraform-docs` using the shared `.terraform-docs.yml` config.
6. **`_header.md`**: Title (e.g., `# Default example`) + one-line description.
7. **`_footer.md`**: Standard Microsoft data collection notice boilerplate.
8. **Naming**: `default` is mandatory; additional examples use descriptive kebab-case names (e.g., `full-dual-hub`, `single-hub-with-firewall`).
9. **Examples must be idempotent** — two consecutive `terraform apply` runs produce zero changes.

### Planned examples for this pattern

| Example | Purpose | Key features exercised |
|---------|---------|----------------------|
| `default` | Minimal deployment — single hub with firewall + bastion | Core pattern integration, basic supplementary modules |
| `full-dual-hub` | Full-featured — internet + intranet hubs, NSGs, NAT GW, peering, flow logs | Dual-hub topology, all supplementary modules, common services VNet peering, flow logs |

> **Note**: Examples use `southeastasia` as the primary region for demonstrations.

**Alternatives Considered**: Only providing tfvars examples — rejected because AVM convention requires self-contained deployable example directories.

---

## R-006: Terraform Version Discrepancy

**Decision**: Keep `required_version = ">= 1.13, < 2.0"` as already set in `terraform.tf`.

**Rationale**: The constitution specifies `~> 1.12` but the existing code uses `>= 1.13, < 2.0`. The existing constraint is stricter (requires at least 1.13) and already established in the codebase. The core pattern module's own constraint is the binding factor — version 0.16.14 supports recent Terraform versions. Aligning with the existing code avoids unnecessary churn.

**Alternatives Considered**: Changing to `~> 1.12` per constitution — rejected because the code already uses a working constraint and the core pattern supports it.

---

## R-007: Existing Code Gap Analysis

**Decision**: The following gaps must be filled to complete the pattern.

### Code present (needs update)
| Component | Status | Action |
|-----------|--------|--------|
| Resource Group module | ✅ Complete | No change |
| Log Analytics Workspace module | ✅ Complete | No change |
| Network Security Group module | ✅ Complete | No change |
| Route Table module | ✅ Present | Review if still needed — core pattern creates route tables internally |
| Private DNS Zone module | ✅ Present | Review if still needed — core pattern manages private DNS zones internally |
| Private DNS Zone Link module | ✅ Present | Review if still needed |
| Managed Identity module | ✅ Present | Update version 0.4.0 → 0.5.0 |
| Storage Account module | ✅ Present | Update version 0.6.7 → 0.6.8 |
| Role Assignment module | ✅ Present | No change |
| Network Watcher module | ✅ Present | No change |
| Locals (key resolution maps) | ✅ Present | Add NAT Gateway + core pattern output lookups |

### Code missing (must add)
| Component | Priority | Action |
|-----------|----------|--------|
| Core pattern module call | **P0** | Add `module.hub_and_spoke_vnet_pattern` with full variable passthrough |
| Core pattern passthrough variable | **P0** | Add `hub_virtual_networks` variable definition |
| NAT Gateway module | **P1** | Add `module.nat_gateway` with flat global map variable |
| NAT Gateway variable | **P1** | Add `nat_gateways` variable definition |
| VNet peering resources | **P1** | Add `azurerm_virtual_network_peering` for hub→spoke and spoke→hub |
| VNet peering variable | **P1** | Add `spoke_virtual_networks` or peering variable |
| Outputs | **P1** | Populate `outputs.tf` (currently empty) |
| Examples (`default/`) | **P2** | Create AVM-style minimal example |
| Examples (`full-dual-hub/`) | **P2** | Create AVM-style full example |
| Examples infrastructure | **P2** | Create `examples/.terraform-docs.yml`, `examples/README.md` |

### Code present but needs review
| Component | Concern |
|-----------|---------|
| Route Table module | Core pattern creates route tables internally. This supplementary module may duplicate functionality. Verify if this is for additional custom route tables beyond what the core pattern creates. |
| Private DNS Zone module | Core pattern manages private DNS zones internally. Verify if this is for additional zones beyond core pattern scope. |
| Managed Identity module | Not in the spec's supplementary modules list. Review if needed for storage account CMK or other purposes. |
| Role Assignment module | Not in the spec's supplementary modules list. Review if needed for specific RBAC scenarios (e.g., flow log storage access). |

---

## R-008: Provider Constraints

**Decision**: Keep existing provider constraints: `azurerm ~> 4.0`, `azapi ~> 2.0`, `random ~> 3.0`.

**Rationale**: The constitution specifies `azapi ~> 2.4` but the existing code uses `~> 2.0`. The broader constraint `~> 2.0` is compatible with `~> 2.4` (2.4 satisfies both). The core pattern 0.16.14 requires `azurerm >= 4.0`. Keeping existing constraints avoids unnecessary churn while remaining compatible.

**Alternatives Considered**: Tightening to `azapi ~> 2.4` per constitution — could be done in a follow-up PR if needed.

---

## R-008b: AVM Module Parameter Passthrough Principle

**Decision**: Every parameter exposed by each AVM module (core pattern and supplementary) MUST be passthrough from the root module's variables / `terraform.tfvars`. No AVM module parameter may be hardcoded in `main.tf` unless it is a computed/derived value (e.g., a resolved resource ID from `locals`).

**Rationale**: Constitution principle III (Configuration-Driven Reusability) mandates that consumers deploy by modifying `terraform.tfvars` only — never by editing module source code. This means:

1. **Core pattern module** (`hub_and_spoke_vnet_pattern`): All inputs (`hub_virtual_networks`, `hub_and_spoke_networks_settings`, `default_naming_convention`, `default_naming_convention_sequence`, `enable_telemetry`, `tags`, `timeouts`) are passed through from root variables.
2. **Supplementary modules** (NSG, NAT GW, LAW, Storage, Network Watcher, etc.): All configuration attributes exposed by the AVM module MUST be passthrough from the corresponding root-level map variable. The `for_each` iterates over the variable map; each attribute inside the module block reads from the variable's object fields.
3. **Exceptions** (computed values only):
   - `resource_group_name` — resolved from `local.resource_group_names[each.value.resource_group_key]`
   - `location` — defaults to `coalesce(each.value.location, var.location)`
   - `tags` — merged: `merge(var.tags, each.value.tags)`
   - NSG/NAT GW IDs injected into core pattern subnet definitions — resolved from `local.*_resource_ids[key]`
   - LAW resource ID for diagnostic settings — resolved from `local.default_log_analytics_workspace_resource_id`

**Implementation rule**: When adding a new AVM module, the developer MUST:
1. Check all inputs of the AVM module (via registry or `terraform-docs`)
2. Add corresponding fields to the root-level variable's `object({...})` type
3. Pass each field through in the `module` block
4. Never hardcode a value that a consumer might need to change

**Alternatives Considered**: Hardcoding sensible defaults inside `main.tf` — rejected because it violates constitution principle III and makes the pattern inflexible.

---

## R-009: `hub_and_spoke_networks_settings` Variable

**Decision**: Expose the core pattern's `hub_and_spoke_networks_settings` as a passthrough variable.

**Rationale**: This variable controls shared resources (DDoS protection plan) across multiple hub networks. It must be passed through to the core pattern without wrapper-level re-implementation (per constitution principle III and FR-010).

**Alternatives Considered**: Decomposing into individual variables — rejected because it would require re-implementing the core pattern's interface.

---

## R-010: Module Instances Beyond Spec Scope

**Decision**: Retain route_table, private_dns_zone, private_dns_zone_link, managed_identity, and role_assignment modules as they serve valid purposes beyond the core pattern's scope.

**Rationale**: 
- **Route Tables**: The core pattern creates firewall and user-subnet route tables, but additional custom route tables may be needed for specific routing scenarios (e.g., forced tunneling through NVAs). The existing module uses the same flat map pattern.
- **Private DNS Zones**: The core pattern manages private link DNS zones, but additional custom private DNS zones (e.g., for on-premises resolution) may be needed.
- **Managed Identity**: Needed for storage account CMK and potentially for other RBAC scenarios.
- **Role Assignment**: Needed for standalone RBAC grants (e.g., granting flow log storage access to Network Watcher).

These modules are pre-existing in the codebase and serve documented purposes. They follow the pattern's map-based variable model and key-based referencing.

**Alternatives Considered**: Removing them to match the spec exactly — rejected because they serve valid use cases and are already implemented.
