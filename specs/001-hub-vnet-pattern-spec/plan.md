# Implementation Plan: PLZ Connectivity Hub VNet Pattern

**Branch**: `001-hub-vnet-pattern-spec` | **Date**: 2026-03-30 | **Spec**: [specs/001-hub-vnet-pattern-spec/spec.md](../../specs/001-hub-vnet-pattern-spec/spec.md)
**Input**: Feature specification from `/specs/001-hub-vnet-pattern-spec/spec.md`

## Resource Module Decomposition Amendment

**Date**: 2026-04-09

The pattern architecture has been fundamentally changed from a monolithic core AVM pattern module to individual AVM resource modules.

### Architecture Change Summary

**REMOVED**: `module "hub_and_spoke_vnet_pattern"` (`Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` v0.16.14)

**NEW Architecture**: Individual AVM resource modules wired together by the wrapper:

| Module | Registry Source | Version | Implementation Status |
|--------|----------------|---------|----------------------|
| Resource Group | `Azure/avm-res-resources-resourcegroup/azurerm` | 0.2.2 | ✅ Fully implemented |
| Network Security Group | `Azure/avm-res-network-networksecuritygroup/azurerm` | 0.5.1 | ✅ Fully implemented |
| Route Table | `Azure/avm-res-network-routetable/azurerm` | 0.5.0 | ✅ Fully implemented |
| NAT Gateway | `Azure/avm-res-network-natgateway/azurerm` | 0.3.2 | ✅ Fully implemented |
| Virtual Network | `Azure/avm-res-network-virtualnetwork/azurerm` | 0.17.1 | ✅ Fully implemented |
| Virtual Network Gateway | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm//modules/virtual-network-gateway` | 0.16.14 | ⬜ Stub — needs full passthrough implementation |
| Public IP | `Azure/avm-res-network-publicipaddress/azurerm` | 0.2.1 | ⬜ Stub — needs full passthrough implementation |
| Firewall Policy | `Azure/avm-res-network-firewallpolicy/azurerm` | 0.3.4 | ⬜ Stub — needs full passthrough implementation |
| Firewall | `Azure/avm-res-network-azurefirewall/azurerm` | 0.4.0 | ⬜ Stub — needs full passthrough implementation |
| Private DNS Zone | `Azure/avm-res-network-privatednszone/azurerm` | 0.5.0 | ✅ Fully implemented |
| Private DNS Zone Link | `Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link` | 0.5.0 | ✅ Fully implemented |
| Network Watcher | `Azure/avm-res-network-networkwatcher/azurerm` | 0.3.2 | ✅ Fully implemented |

### Variable Interface Changes

The monolithic `hub_virtual_networks` variable is replaced with individual flat global map variables per resource type:

| Old Variable | New Variables | Notes |
|-------------|--------------|-------|
| `hub_virtual_networks` | `virtual_networks`, `firewalls`, `firewall_policies`, `virtual_network_gateways`, `public_ips` | Decomposed into individual maps |
| `hub_and_spoke_networks_settings` | Removed | DDoS via `virtual_networks` entries directly |
| `default_naming_convention` | Removed | Consumers name resources explicitly |
| `default_naming_convention_sequence` | Removed | No longer applicable |
| `timeouts` | Removed (root-level) | Per-resource in individual variables |
| — | `route_tables` | Restored from Simplification Amendment |
| — | `private_dns_zones` | Restored from Simplification Amendment |
| — | `byo_private_dns_zone_links` | Restored from Simplification Amendment |

### Key Resolution Pattern

The wrapper still resolves cross-resource references via key-based lookups in `locals.tf`:
- `resource_group_key` → `local.resource_group_names[key]` / `local.resource_group_resource_ids[key]`
- `nsg_key` / `network_security_group_key` → `local.nsg_resource_ids[key]` (for subnet associations)
- `nat_gateway_key` → `local.nat_gateway_resource_ids[key]` (for subnet associations)
- `route_table_key` → `local.rt_resource_ids[key]` (for subnet associations)
- `virtual_network_key` → `local.vnet_resource_ids[key]` (for DNS zone VNet links, flow logs)
- `managed_identity_key` → `local.managed_identity_principal_ids[key]` (for role assignments)

### Implementation Tasks (Remaining)

The following stub modules need full passthrough implementation:

1. **`module.virtual_network_gateway`** — Add all passthrough parameters from `var.virtual_network_gateways`, resolve resource IDs via locals
2. **`module.public_ip`** — Add all passthrough parameters from `var.public_ips`, resolve resource IDs via locals
3. **`module.firewall_policy`** — Add all passthrough parameters from `var.firewall_policies`, resolve resource IDs via locals
4. **`module.firewall`** — Add all passthrough parameters from `var.firewalls`, resolve resource IDs via locals

Each stub module needs:
- Variable definition in `variables.tf` (flat global map with explicit type constraints)
- Full parameter passthrough in `main.tf` (no hardcoded values)
- Local lookups in `locals.tf` for output ID resolution
- Output definitions in `outputs.tf`
- Precondition validations for key references

### Impact on Examples

Examples must be rewritten to use the new flat variable interface. The `terraform.tfvars` structure changes from nested `hub_virtual_networks` entries to individual resource maps.

### Impact on Previous Amendments

The Simplification Amendment is partially superseded — modules removed because the core pattern handled them are now restored as individual AVM resource modules.

> **Note**: The original plan content below is preserved for historical context. Where it conflicts with this amendment, this amendment takes precedence.

## Simplification Amendment

**Date**: 2026-03-30

The pattern has been simplified to remove supplementary modules whose capabilities are already handled by the core pattern or belong outside the pattern scope:
- **Removed modules**: log_analytics_workspace, route_table, private_dns_zone, private_dns_zone_link, managed_identity, storage_account, role_assignment, azurerm_virtual_network_peering
- **Removed provider**: `random ~> 3.0`
- **Remaining providers**: `azurerm ~> 4.0`, `azapi ~> 2.0`
- **Remaining supplementary modules**: resource_group (0.2.2), network_security_group (0.5.1), nat_gateway (0.3.2), network_watcher (0.3.2)
- Consumers pass `diagnostic_settings` directly to NSG/NAT GW variables (no auto-LAW resolution)
- Flow logs take `storage_account_id` directly (no pattern-managed storage accounts)

> **Note**: The original plan content below is preserved for historical context. Where it conflicts with this amendment, the amendment takes precedence.

## Summary

Implement a configuration-driven Terraform wrapper pattern that provisions Azure Landing Zone connectivity hub VNet infrastructure. The core engine is the AVM pattern module `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` (v0.16.14), supplemented by individual AVM resource modules for NSGs, NAT Gateways, and network watcher. All AVM module parameters are passthrough from root-level variables — consumers configure entirely via `terraform.tfvars`. Examples follow AVM conventions with terraform-docs-generated READMEs.

## Technical Context

**Language/Version**: Terraform `>= 1.13, < 2.0` (HCL)
**Primary Dependencies**: AVM core pattern `0.16.14`, 4 supplementary AVM resource modules
**Providers**: `azurerm ~> 4.0`, `azapi ~> 2.0`
**Storage**: N/A (IaC pattern — no application storage)
**Testing**: `terraform fmt -check`, `terraform validate`, `terraform plan`, `terraform-docs` freshness, tflint
**Target Platform**: Azure (ALZ connectivity subscription)
**Project Type**: Terraform root module (single module, no nested submodules)
**Performance Goals**: N/A (infrastructure provisioning)
**Constraints**: Constitution v1.0.0 — 4 NON-NEGOTIABLE principles (I, II, IV, V); all parameters passthrough from tfvars
**Scale/Scope**: Multi-hub, multi-region, multi-subscription hub VNet deployments

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Terraform-Only Declarative (NON-NEGOTIABLE) | ✅ PASS | Zero scripts, zero provisioners in design |
| II. AVM Exclusive — Core Pattern First (NON-NEGOTIABLE) | ✅ PASS | Core pattern v0.16.14 is primary engine; supplementary modules justified (see research.md R-001, R-004) |
| III. Configuration-Driven Reusability | ✅ PASS | All params passthrough from tfvars; map-based variables; central location/tags/telemetry |
| IV. Security by Default (NON-NEGOTIABLE) | ✅ PASS | secure-by-default values in variables; `public_network_access_enabled = false`; TLS 1.2+; default-deny NSG posture |
| V. Reliability & Determinism (NON-NEGOTIABLE) | ✅ PASS | Pinned module versions; idempotent design; timeouts exposed |
| VI. Tooling-Based Documentation (NON-NEGOTIABLE) | ✅ PASS | terraform-docs generated READMEs; AVM-style descriptions on all variables |
| VII. Operability & Observability | ✅ PASS | All core + supplementary outputs exposed; diagnostic settings on supplementary resources |
| VIII. Extensibility & Composability | ✅ PASS | Map-based variables; key-based cross-references; output contracts for downstream patterns |

**Post-Phase-1 Re-check**: All gates still pass. The data model, variable contracts, and example contracts are aligned with all 8 principles.

## Project Structure

### Documentation (this feature)

```text
specs/001-hub-vnet-pattern-spec/
├── plan.md              # This file
├── research.md          # Phase 0 output — AVM versions, gap analysis, example conventions
├── data-model.md        # Phase 1 output — entity model, key resolution, lifecycle
├── quickstart.md        # Phase 1 output — consumer quickstart guide
├── contracts/           # Phase 1 output — interface contracts
│   ├── variable-interface.md   # Input/output variable contracts
│   └── example-contracts.md    # AVM-style example directory contracts
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
.                                    # Terraform root module
├── main.tf                          # Module calls: core pattern + all supplementary modules
├── variables.tf                     # All input variable definitions (passthrough)
├── outputs.tf                       # All outputs (core pattern + supplementary)
├── locals.tf                        # Key-to-resource-ID resolution maps
├── terraform.tf                     # Terraform + provider version constraints
├── README.md                        # Auto-generated by terraform-docs (root)
├── _header.md                       # Header for root README
├── _footer.md                       # Footer for root README
├── .terraform-docs.yml              # terraform-docs config (root)
│
├── examples/
│   ├── .terraform-docs.yml          # Shared terraform-docs config for examples
│   ├── README.md                    # Boilerplate example instructions
│   ├── default/                     # REQUIRED — minimal single-hub deployment
│   │   ├── main.tf                  # terraform{} + provider{} + module call (source = "../../")
│   │   ├── outputs.tf
│   │   ├── _header.md
│   │   └── README.md                # Auto-generated
│   └── full-dual-hub/               # Full — internet + intranet hubs, peering, flow logs
│       ├── main.tf
│       ├── outputs.tf
│       ├── _header.md
│       └── README.md                # Auto-generated
│
└── specs/                           # Feature specs (not deployed)
```

**Structure Decision**: Single Terraform root module with AVM-style `examples/` directory. No nested submodules — the core AVM pattern handles internal module composition. Examples follow standard AVM conventions: self-contained, zero-input, deployable, terraform-docs generated READMEs.

## Module Version Inventory

| Module | Registry Source | Version | Status |
|--------|----------------|---------|--------|
| Core pattern | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` | **0.16.14** | **ADD** (TODO placeholder exists) |
| Resource Group | `Azure/avm-res-resources-resourcegroup/azurerm` | 0.2.2 | Current |
| Log Analytics Workspace | `Azure/avm-res-operationalinsights-workspace/azurerm` | 0.5.1 | Current |
| Network Security Group | `Azure/avm-res-network-networksecuritygroup/azurerm` | 0.5.1 | Current |
| Route Table | `Azure/avm-res-network-routetable/azurerm` | 0.5.0 | Current |
| Private DNS Zone | `Azure/avm-res-network-privatednszone/azurerm` | 0.5.0 | Current |
| Managed Identity | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | **0.5.0** | **UPDATE** from 0.4.0 |
| Storage Account | `Azure/avm-res-storage-storageaccount/azurerm` | **0.6.8** | **UPDATE** from 0.6.7 |
| Role Assignment | `Azure/avm-res-authorization-roleassignment/azurerm` | 0.3.0 | Current |
| Network Watcher | `Azure/avm-res-network-networkwatcher/azurerm` | 0.3.2 | Current |
| NAT Gateway | `Azure/avm-res-network-natgateway/azurerm` | **0.3.2** | **ADD** (missing) |

## Implementation Tasks Overview

### P0 — Core Pattern Integration (Blocking)

1. **Add core pattern module call** in `main.tf` (replace TODO placeholder)
   - `module.hub_and_spoke_vnet_pattern` with source `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` version `0.16.14`
   - All inputs passthrough from root variables: `hub_virtual_networks`, `hub_and_spoke_networks_settings`, `default_naming_convention`, `default_naming_convention_sequence`, `enable_telemetry`, `tags`, `timeouts`
   - Subnet `network_security_group.id` and `nat_gateway.id` resolved from `locals` key maps

2. **Add core pattern passthrough variables** in `variables.tf` (replace TODO placeholder)
   - `hub_virtual_networks` — map-based, matching core pattern's type signature
   - `hub_and_spoke_networks_settings` — shared settings (DDoS plan)
   - `default_naming_convention` — naming templates
   - `default_naming_convention_sequence` — sequence config
   - `timeouts` — operation timeouts

3. **Update `locals.tf`** with core pattern output lookups
   - `vnet_resource_ids` from `module.hub_and_spoke_vnet_pattern.virtual_network_resource_ids`
   - `firewall_private_ips` from `module.hub_and_spoke_vnet_pattern.firewall_private_ip_addresses`

### P1 — Missing Supplementary Modules

4. **Add NAT Gateway module** in `main.tf`
   - `module.nat_gateway` with `for_each = var.nat_gateways`
   - Source `Azure/avm-res-network-natgateway/azurerm` version `0.3.2`
   - All parameters passthrough from `var.nat_gateways[each.key].*`
   - Resource group resolved from `local.resource_group_names[each.value.resource_group_key]`

5. **Add `nat_gateways` variable** in `variables.tf`
   - Flat global map with same pattern as `network_security_groups`
   - Fields: `name`, `resource_group_key`, `location?`, `sku_name?`, `idle_timeout_in_minutes?`, `zones?`, `public_ip_configuration?`, `diagnostic_settings?`, `lock?`, `role_assignments?`, `tags?`

6. **Add `nat_gateway_resource_ids` local** in `locals.tf`

7. **Add VNet peering resources** in `main.tf`
   - `azurerm_virtual_network_peering.hub_to_spoke` with `for_each = var.spoke_virtual_networks`
   - `azurerm_virtual_network_peering.spoke_to_hub` with `for_each = var.spoke_virtual_networks`
   - Justified: no standalone AVM peering module exists (see research.md R-003)

8. **Add `spoke_virtual_networks` variable** in `variables.tf`
   - Map keyed by `spoke_key`
   - Fields: `spoke_vnet_resource_id`, `hub_key`, `allow_forwarded_traffic?`, `allow_gateway_transit?`, `use_remote_gateways?`, `allow_virtual_network_access?`

### P1 — Version Updates

9. **Update managed identity module** version from `0.4.0` to `0.5.0`
10. **Update storage account module** version from `0.6.7` to `0.6.8`

### P1 — Outputs

11. **Populate `outputs.tf`** with all required outputs:
    - Core pattern passthrough: `hub_virtual_network_ids`, `hub_virtual_network_names`, `firewall_private_ip_addresses`, `firewall_resource_names`, `bastion_host_dns_names`, `route_tables_firewall`, `route_tables_user_subnets`, `private_dns_zone_resource_ids`
    - Supplementary: `resource_group_ids`, `resource_group_names`, `nsg_resource_ids`, `nat_gateway_resource_ids`, `log_analytics_workspace_id`, `storage_account_resource_ids`, `managed_identity_principal_ids`, `network_watcher_id`
    - Peering: `spoke_peering_ids`
    - All outputs with AVM-style `description` attributes

### P2 — Examples (AVM Convention)

12. **Create `examples/.terraform-docs.yml`** — shared terraform-docs config (AVM standard)
13. **Create `examples/README.md`** — boilerplate instructions
14. **Create `examples/default/` example** — minimal single-hub deployment
    - `main.tf`: `terraform{}` + `provider{}` + random region/naming + module call using `source = "../../"`
    - `outputs.tf`: key outputs
    - `_header.md`: `# Default example` + description
    - Zero required input variables; self-contained resource group; `enable_telemetry = false`
    - Primary region: `southeastasia`
15. **Create `examples/full-dual-hub/` example** — dual-hub internet + intranet topology
    - Two hubs in the same region (`hub_internet` + `hub_intranet`) per the reference architecture:
      - **Internet Egress/Ingress hub** (`hub_internet`): Firewall + NAT Gateway + Bastion, non-routable address space
      - **Intranet Ingress hub** (`hub_intranet`): Firewall only, routable address space
    - Common Services VNet peered to both hubs (DNS Resolver subnet)
    - NSGs on user subnets, NAT Gateway on internet hub
    - Flow logs with wrapper-created storage account + traffic analytics
    - All parameters passthrough from variables
    - Region: `southeastasia`

### P2 — Documentation

16. **Run `terraform-docs`** to generate all `README.md` files (root + examples)
17. **Validate** `terraform fmt -check -recursive` + `terraform validate` on root + all examples

### P3 — Quality & Review

18. **Verify passthrough completeness** — audit every `module` block to ensure no hardcoded values
19. **Verify constitution compliance** — self-assessment checklist against all 8 principles
20. **Verify idempotency** — `terraform plan` with unchanged inputs = zero changes

## Passthrough Parameter Principle

> **CRITICAL**: Every parameter exposed by each AVM module (core pattern and supplementary) MUST be passthrough from root-level variables / `terraform.tfvars`. This is a non-negotiable design principle derived from constitution principle III.

### What "passthrough" means in practice

```hcl
# In variables.tf — expose the parameter
variable "network_security_groups" {
  type = map(object({
    name               = string
    resource_group_key = string
    location           = optional(string)
    security_rules     = optional(map(object({...})), {})
    diagnostic_settings = optional(map(object({...})), {})
    # ... every AVM module parameter has a corresponding field here
  }))
}

# In main.tf — passthrough, don't hardcode
module "network_security_group" {
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version  = "0.5.1"
  for_each = var.network_security_groups

  name                = each.value.name
  resource_group_name = local.resource_group_names[each.value.resource_group_key]
  location            = coalesce(each.value.location, var.location)
  security_rules      = each.value.security_rules          # passthrough
  diagnostic_settings = local.resolved_diag_settings(...)   # computed (resolves LAW key)
  lock                = each.value.lock                     # passthrough
  role_assignments    = local.resolved_role_assignments(...) # computed (resolves identity keys)
  tags                = merge(var.tags, each.value.tags)     # computed (merge)
  enable_telemetry    = var.enable_telemetry                 # central passthrough
}
```

### Allowed exceptions (computed values only)

| Exception | Reason |
|-----------|--------|
| `resource_group_name` | Resolved from `local.resource_group_names[each.value.resource_group_key]` |
| `location` | Defaulted via `coalesce(each.value.location, var.location)` |
| `tags` | Merged via `merge(var.tags, each.value.tags)` |
| `diagnostic_settings.workspace_resource_id` | Resolved from `local.default_log_analytics_workspace_resource_id` when `use_default_log_analytics = true` |
| `role_assignments.principal_id` | Resolved from `local.managed_identity_principal_ids[managed_identity_key]` when key-based |
| `network_security_group.id` / `nat_gateway.id` | Resolved from `local.nsg_resource_ids[key]` / `local.nat_gateway_resource_ids[key]` |

## AVM Example Conventions (Detailed)

### Directory layout per example
```
examples/<name>/
├── main.tf           # terraform{} + provider{} + module call (source = "../../")
├── outputs.tf        # At least one output
├── _header.md        # Title + one-line description
└── README.md         # Auto-generated by terraform-docs (NEVER hand-edited)
```

### Key rules
1. **No separate `terraform.tf`** — everything in `main.tf`
2. **Module source**: `source = "../../"` with commented-out registry hint
3. **Zero required input variables** — all values from `random_*` / `Azure/naming/azurerm` / `Azure/regions/azurerm`
4. **Each example creates its own resource group(s)** — self-contained, destroyable
5. **`_header.md`**: `# <Title>` + one-line description
6. **README.md**: Auto-generated by `terraform-docs` using shared `examples/.terraform-docs.yml`
7. **All parameters passthrough** — no hardcoded values in the module call
8. **Idempotent** — two consecutive `terraform apply` = zero changes
9. **Primary example region**: `southeastasia`

### Planned examples

| Example | Purpose | Region |
|---------|---------|--------|
| `default` | Minimal — single hub, firewall + bastion, one NSG, wrapper-created LAW | southeastasia |
| `full-dual-hub` | Dual-hub — internet egress/ingress hub (FW + NAT GW) + intranet ingress hub (FW), common services VNet with DNS resolver, peering, flow logs | southeastasia |

## Complexity Tracking

No constitution violations requiring justification. All design decisions align with the 8 principles.
