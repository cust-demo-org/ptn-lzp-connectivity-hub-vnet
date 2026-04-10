# Feature Specification: PLZ Connectivity Hub VNet Terraform Pattern

**Feature Branch**: `001-hub-vnet-pattern-spec`
**Created**: 2026-03-30
**Status**: Draft — Amended (Resource Module Decomposition)
**Input**: User description: "Define what the plz-connectivity-hub-vnet pattern provides, how it is consumed, and what constraints apply — without implementing Terraform code."

---

## Resource Module Decomposition Amendment

**Date**: 2026-04-09 | **Reason**: Replace the monolithic AVM pattern module (`hub_and_spoke_vnet_pattern`) with individual AVM resource modules for greater flexibility and granular control over each resource type.

### Rationale

The core AVM pattern module `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` bundles VNet, firewall, bastion, gateways, DNS, and route tables into a single opinionated module call. This limits the pattern's ability to:
- Independently manage individual resource lifecycles (e.g., update firewall policy without touching VNets)
- Use the latest AVM resource module versions independently
- Add custom wiring logic (e.g., cross-resource key resolution for route tables, DNS zones, VNet peering)
- Support resources the pattern module doesn't natively expose (e.g., standalone public IPs, BYO DNS zone links)

The decomposed architecture replaces the single pattern module with individual AVM resource modules, giving the wrapper full control over each resource while maintaining the same consumer-facing variable interface.

### Architecture Change

**Removed**:
- `module "hub_and_spoke_vnet_pattern"` (`Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` v0.16.14)

**Added/Retained AVM Resource Modules**:

| Module | Registry Source | Version | Status |
|--------|----------------|---------|--------|
| Resource Group | `Azure/avm-res-resources-resourcegroup/azurerm` | 0.2.2 | Fully implemented |
| Network Security Group | `Azure/avm-res-network-networksecuritygroup/azurerm` | 0.5.1 | Fully implemented |
| Route Table | `Azure/avm-res-network-routetable/azurerm` | 0.5.0 | Fully implemented |
| NAT Gateway | `Azure/avm-res-network-natgateway/azurerm` | 0.3.2 | Fully implemented |
| Virtual Network | `Azure/avm-res-network-virtualnetwork/azurerm` | 0.17.1 | Fully implemented |
| Virtual Network Gateway | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm//modules/virtual-network-gateway` | 0.16.14 | Stub — needs implementation |
| Public IP | `Azure/avm-res-network-publicipaddress/azurerm` | 0.2.1 | Stub — needs implementation |
| Firewall Policy | `Azure/avm-res-network-firewallpolicy/azurerm` | 0.3.4 | Stub — needs implementation |
| Firewall | `Azure/avm-res-network-azurefirewall/azurerm` | 0.4.0 | Stub — needs implementation |
| Private DNS Zone | `Azure/avm-res-network-privatednszone/azurerm` | 0.5.0 | Fully implemented |
| Private DNS Zone Virtual Network Link | `Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link` | 0.5.0 | Fully implemented |
| Network Watcher | `Azure/avm-res-network-networkwatcher/azurerm` | 0.3.2 | Fully implemented |

### Variable Interface Changes

- `hub_virtual_networks` — **REMOVED**. No longer a single monolithic map. Individual resource variables (`virtual_networks`, `firewalls`, `firewall_policies`, `public_ips`, `virtual_network_gateways`) replace the nested structure.
- `hub_and_spoke_networks_settings` — **REMOVED**. DDoS protection is now configured directly on `virtual_networks` entries.
- `default_naming_convention` — **REMOVED**. Consumers name resources explicitly via individual resource variables.
- `default_naming_convention_sequence` — **REMOVED**. No longer applicable without the pattern module's naming engine.
- `timeouts` — **REMOVED** as a root-level variable. Timeouts are configured per-resource within individual variables.
- `virtual_networks` — **ADDED**. Flat global map for VNet definitions with subnets, peerings, DNS, DDoS, etc.
- `route_tables` — **RESTORED**. Flat global map for route table definitions.
- `private_dns_zones` — **RESTORED**. Flat global map for private DNS zone definitions with VNet links.
- `byo_private_dns_zone_virtual_network_links` — **RESTORED**. Flat global map for BYO DNS zone VNet link definitions.
- `virtual_network_gateways` — **ADDED**. Flat global map for VPN/ExpressRoute gateway definitions.
- `public_ips` — **ADDED**. Flat global map for standalone public IP definitions.
- `firewall_policies` — **ADDED**. Flat global map for firewall policy definitions.
- `firewalls` — **ADDED**. Flat global map for Azure Firewall definitions.

### Output Changes

- Outputs previously sourced from `module.hub_and_spoke_vnet_pattern` (`hub_virtual_network_names`, `firewall_resource_names`, `bastion_host_dns_names`, `route_tables_firewall`, `route_tables_user_subnets`) are now sourced from individual resource modules.
- New outputs may be added for `virtual_network_ids`, `virtual_network_gateway_ids`, `public_ip_ids`, `firewall_ids`, `firewall_policy_ids`, `private_dns_zone_ids`, `route_table_ids`.

### Impact on Constitution Principles

- **Principle II (AVM Exclusive)**: Still satisfied — all resources use AVM modules. The change moves from a single AVM *pattern* module to multiple AVM *resource* modules.
- **Principle III (Configuration-Driven)**: Still satisfied — all parameters passthrough from tfvars via flat global map variables.
- All other principles remain unaffected.

### Impact on Previous Amendments

- The **Simplification Amendment** (2026-03-30) is partially superseded: modules that were removed because the core pattern handled them (route_table, private_dns_zone, etc.) are now **restored** as the pattern no longer delegates to the core pattern module.

> **Note**: The original specification and previous amendments below are preserved for historical context. Where they conflict with this amendment, this amendment takes precedence.

---

## Simplification Amendment

**Date**: 2026-03-30 | **Reason**: Reduce pattern complexity by removing supplementary modules whose capabilities are already handled by the core pattern or belong outside the pattern scope entirely.

### Modules/Resources Removed

| Removed Module/Resource | Reason |
|--------------------------|--------|
| `azurerm_virtual_network_peering` (hub↔spoke) | Already handled by `hub_and_spoke_vnet_pattern` core module |
| `avm-res-storage-storageaccount` (Storage Account) | Not the pattern's responsibility; Network Watcher takes `storage_account_id` directly |
| `avm-res-authorization-roleassignment` (Role Assignment) | Not needed without pattern-managed storage/identity |
| `avm-res-network-routetable` (Route Table) | Already handled by `hub_and_spoke_vnet_pattern` core module |
| `avm-res-managedidentity-userassignedidentity` (Managed Identity) | Not needed without pattern-managed storage/role assignments |
| `avm-res-network-privatednszone` (Private DNS Zone) | Already handled by `hub_and_spoke_vnet_pattern` core module |
| Private DNS Zone VNet Links | Already handled by `hub_and_spoke_vnet_pattern` core module |
| `avm-res-operationalinsights-workspace` (Log Analytics Workspace) | Not the pattern's responsibility; consumers provide LAW IDs via diagnostic_settings directly |
| `hashicorp/random` provider | Was only used for storage account suffix — no longer needed |

### Variables Removed

`byo_log_analytics_workspace`, `log_analytics_workspace_configuration`, `route_tables`, `private_dns_zones`, `byo_private_dns_zone_virtual_network_links`, `managed_identities`, `spoke_virtual_networks`, `storage_accounts`, `role_assignments`

### Outputs Removed

`log_analytics_workspace_id`, `storage_account_resource_ids`, `managed_identity_principal_ids`, `private_dns_zone_resource_ids`, `spoke_peering_ids`

### Variables Simplified

- `network_security_groups` / `nat_gateways`: Removed `use_default_log_analytics` and `managed_identity_key` from `diagnostic_settings` and `role_assignments`. Consumers pass `diagnostic_settings` directly.
- `flowlog_configuration`: Flow logs take `storage_account_id` (string) directly instead of `storage_account.key` resolution.

### Remaining Supplementary Modules

| Module | Version | Justification |
|--------|---------|---------------|
| `avm-res-resources-resourcegroup` | 0.2.2 | Core pattern does not create resource groups |
| `avm-res-network-networksecuritygroup` | 0.5.1 | Core pattern accepts NSG IDs but does not create NSGs |
| `avm-res-network-natgateway` | 0.3.2 | Core pattern accepts NAT GW IDs but does not create NAT GWs |
| `avm-res-network-networkwatcher` | 0.3.2 | Core pattern does not manage network watcher or flow logs |

### Impact on Requirements

- **FR-005** (LAW provisioning): **SUPERSEDED** — Pattern no longer provisions LAW. Consumers provide LAW resource IDs via `diagnostic_settings` on individual resources.
- **FR-007** (VNet peering): **SUPERSEDED** — Pattern no longer manages hub-to-spoke peering. Already handled by core pattern.
- **FR-009** (Diagnostic settings for supplementary resources): **AMENDED** — Consumers pass `diagnostic_settings` directly to NSG/NAT GW variables.
- **FR-017** (Provider constraints): **AMENDED** — `random` provider removed. Only `azurerm ~> 4.0` and `azapi ~> 2.0`.
- **FR-025** (LAW retention): **SUPERSEDED** — Pattern no longer creates LAW.
- **FR-026** (Storage account for flow logs): **SUPERSEDED** — Pattern no longer creates storage accounts. Flow logs take `storage_account_id` directly.
- **FR-032** (Common services peering): **SUPERSEDED** — Pattern no longer manages spoke peering.
- **FR-034** (BYO precedence): **SUPERSEDED** — No BYO resources managed by pattern.
- **FR-035** (Managed identities): **SUPERSEDED** — Pattern no longer creates managed identities.
- **FR-036** (Role assignments): **SUPERSEDED** — Pattern no longer creates role assignments.

### Impact on User Stories

- **US-3** (Hub-to-spoke peering): **SUPERSEDED** — Peering is handled by core pattern.
- **US-4** (BYO LAW): **SUPERSEDED** — LAW is not managed by this pattern.

> **Note**: The original specification content below is preserved for historical context. Where it conflicts with this amendment, the amendment takes precedence.

---

## Overview & Intent *(mandatory)*

### Problem Statement

Enterprise organisations adopting the Azure Landing Zones (ALZ) architecture require a **connectivity hub virtual network** that acts as the central network transit point for all spoke workloads. Provisioning this hub infrastructure manually — or through ad-hoc configurations — creates inconsistency, security gaps, and operational drift across environments and regions.

This pattern solves that problem by providing a **single, declarative, configuration-driven wrapper** that platform teams consume to provision hub VNet infrastructure aligned to the Microsoft Cloud Adoption Framework (CAF). The wrapper delegates the majority of resource provisioning to the official AVM core pattern module (`Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm`) and supplements it with a controlled set of additional AVM resource modules only where the core pattern does not create the resource itself.

### Intended Consumers

- **Primary consumers**: Platform / connectivity teams responsible for provisioning and operating hub network infrastructure within an ALZ hierarchy.
- **Downstream dependents**: Spoke landing zone patterns that peer to the hub, consume DNS resolution, route traffic through the hub firewall, and leverage bastion for secure access.

### Value Proposition

- One codebase, many environments: a single parameterised pattern serves every hub deployment across subscriptions, regions, and teams.
- Constitutional compliance baked in: every resource follows the PLZ Connectivity Hub VNet Pattern Constitution v1.0.0 principles.
- Reduced blast radius: the core AVM pattern is the primary engine; only documented, justified supplementary modules are permitted.

---

## Clarifications

### Session 2026-03-30

- Q: Does this pattern create peering on both sides (hub→spoke AND spoke→hub), or only the hub side? → A: Both directions (hub→spoke + spoke→hub) managed by this pattern.
- Q: Are NSGs defined per-hub (nested) or as a flat global map shared across all hubs? → A: Global flat map at root level; any hub subnet can reference any NSG by key.
- Q: What should the default log retention period be when the wrapper creates a new LAW? → A: 30 days.
- Q: Should the wrapper create a storage account for flow logs, or require BYO only? → A: Wrapper creates a storage account via a supplementary AVM module, with BYO fallback.
- Q: Does the pattern create its own resource group(s) or expect pre-existing ones? → A: Pattern creates its own resource group(s); other hub resources reference the RG via keys. Central variables for location, enable_telemetry, and tags.

---

## In-Scope / Out-of-Scope Summary *(mandatory)*

### In Scope

The pattern MUST provision or configure the following capabilities:

| Capability | Responsibility |
|------------|---------------|
| Hub virtual network(s) with configurable address spaces, DNS servers, DDoS protection, and subnets | Core pattern |
| Azure Firewall (Basic / Standard / Premium) with IP configurations, management IP, availability zones | Core pattern |
| Azure Firewall Policy (DNS proxy, intrusion detection, TLS inspection, threat intelligence, explicit proxy) | Core pattern |
| Azure Bastion (Basic / Standard) with public IP and configurable features | Core pattern |
| VPN Gateway (site-to-site, point-to-site, local network gateways, active-active, BGP) | Core pattern |
| ExpressRoute Gateway with circuit connections and peering | Core pattern |
| Private DNS Zones (private link zones, auto-registration, virtual network links, resolution policies) | Core pattern |
| Additional Private DNS Zone VNet links for zones not managed by the core pattern (e.g., linking BYO DNS zones to hub VNets) | Supplementary module (BYO links only — core pattern handles its own zone links) |
| Private DNS Resolver (inbound/outbound endpoints, forwarding rulesets) | Core pattern |
| DDoS Protection Plan (shared across hub networks) | Core pattern |
| Route tables (firewall, user subnets, gateway route tables) | Core pattern |
| Additional custom route tables beyond what the core pattern creates (e.g., for supplementary subnets not managed by the core pattern) | Supplementary module (retained per research.md R-010 — serves valid purposes beyond core pattern scope) |
| Network Security Groups (created by wrapper, IDs passed to core pattern for subnet association) | Supplementary module |
| NAT Gateways (created by wrapper, IDs passed to core pattern for subnet association) | Supplementary module |
| Log Analytics Workspace (provisioned by wrapper or accepted as BYO resource ID; used for diagnostics) | Supplementary module |
| Network Watcher and flow-log configuration | Supplementary module |
| Storage Account for flow logs (provisioned by wrapper or accepted as BYO resource ID) | Supplementary module |
| Bidirectional VNet peering (hub→spoke + spoke→hub) to existing spoke virtual networks | Supplementary module |
| Diagnostic settings for supplementary resources (NSGs, NAT Gateways) | Wrapper responsibility |
| Tags inherited globally and overridable per resource | Wrapper + core pattern |
| Resource group(s) created by the wrapper; hub resources reference RG by key | Wrapper responsibility |

### Out of Scope

The pattern MUST NOT provision or manage:

- Spoke virtual network creation (spokes are provisioned by their own landing zone patterns; this pattern peers TO existing spokes only).
- Resource group creation for spoke or workload resources (the wrapper only creates resource groups for hub infrastructure).
- Application-level workload infrastructure.
- Key Vaults, Backup Vaults, Recovery Services Vaults (Managed Identities are in scope per FR-035 when required for RBAC operations).
- General-purpose Storage Accounts (the wrapper only creates storage accounts scoped to flow log storage; all other storage belongs in spoke/shared-services patterns).
- Firewall Rule Collection Groups, Application Rules, Network Rules, NAT Rules (managed separately to allow independent lifecycle).
- Entra ID tenant configuration.
- Management group hierarchy or Azure Policy definitions.
- Billing, cost management, or subscription vending.
- CI/CD pipeline definition (pipelines invoke this pattern but are not governed by it).

---

## Architecture Description *(mandatory)*

### Core Pattern vs Supplementary Modules

The architecture follows a strict two-tier model mandated by the constitution:

**Tier 1 — Core Pattern (Primary Engine)**
The AVM core pattern module `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` is the single source of truth for all resources it supports. The wrapper MUST NOT duplicate or re-implement any capability the core pattern already provides. The core pattern internally manages hub VNets, subnets, firewall, firewall policy, bastion, VPN gateway, ExpressRoute gateway, private DNS zones, private DNS resolver, DDoS protection, and route tables.

**Tier 2 — Supplementary AVM Resource Modules (Gap-Fillers)**
Supplementary modules are permitted ONLY when the core pattern does not create the resource type but accepts the resource's ID as an input. Each supplementary module MUST be individually justified. The currently justified supplementary modules are:

| Module | Justification |
|--------|---------------|
| Network Security Group (`avm-res-network-networksecuritygroup`) | Core pattern accepts NSG IDs on subnets but does not create NSGs |
| NAT Gateway (`avm-res-network-natgateway`) | Core pattern accepts NAT Gateway IDs on subnets but does not create NAT Gateways |
| Log Analytics Workspace (`avm-res-operationalinsights-workspace`) | Core pattern accepts LAW IDs for diagnostics but does not create a workspace |
| Network Watcher (`avm-res-network-networkwatcher`) | Core pattern does not manage network watcher or flow logs |
| Storage Account (`avm-res-storage-storageaccount`) | Flow logs require a storage account destination; core pattern does not create storage accounts |
| User-Assigned Managed Identity (`avm-res-managedidentity-userassignedidentity`) | Flow log storage access and other identity-based operations require managed identities; core pattern does not create them |
| Role Assignment (`avm-res-authorization-roleassignment`) | Managed identities require RBAC grants to access resources (e.g., storage accounts); core pattern does not manage role assignments |
| VNet Peering (bidirectional hub↔spoke) | Core pattern manages mesh peering between hubs but does not peer to external spoke VNets; wrapper creates both directions |

Before adding ANY new supplementary module, the contributor MUST verify the capability is not already provided by the core pattern, check the core pattern's latest release notes, and document the justification.

### Hub-to-Spoke Connectivity Model

The pattern MUST support **bidirectional** peering between hub virtual networks and **existing** spoke virtual networks. For each spoke entry, the pattern MUST create both the hub→spoke and spoke→hub peering resources from a single configuration. Spoke VNets are provisioned by their own landing zone patterns; this pattern does not create spokes. Peering MUST be defined via a map-based variable where each entry is keyed by a `spoke_key` and supplies the spoke's `resource_id`. The pattern resolves keys to resource IDs internally. The deploying identity MUST have sufficient RBAC permissions (e.g., Network Contributor) on both the hub and spoke VNets to create peering resources on both sides.

### DNS Responsibilities

The core pattern manages private DNS zones (including private link zones), auto-registration, virtual network links, resolution policies, and the private DNS resolver (inbound/outbound endpoints, forwarding rulesets). The wrapper MUST expose the core pattern's DNS-related variables without modification.

### Firewall Responsibilities

The core pattern manages the Azure Firewall resource and the Azure Firewall Policy resource. The wrapper MUST expose the core pattern's firewall-related variables (SKU selection, availability zones, IP configurations, policy settings including DNS proxy, intrusion detection, TLS inspection, and threat intelligence). Firewall Rule Collection Groups, Application Rules, Network Rules, and NAT Rules are explicitly out of scope and MUST be managed separately.

### Gateway Responsibilities

The core pattern manages VPN Gateway (site-to-site, point-to-site, local network gateways, active-active, BGP) and ExpressRoute Gateway (circuit connections, peering). The wrapper MUST expose the core pattern's gateway-related variables without modification.

### Observability Responsibilities

- The wrapper MUST provision a Log Analytics Workspace via a supplementary module OR accept a BYO resource ID, and pass that ID to the core pattern for firewall insights and diagnostics. When the wrapper creates a new LAW, the default retention period MUST be **30 days**. Consumers MUST be able to override this value via the LAW variable.
- The wrapper MUST enable diagnostic settings for every supplementary resource that supports them (NSGs, NAT Gateways), sending logs to the Log Analytics Workspace.
- The core pattern handles diagnostics for its own managed resources internally.
- The wrapper MUST provision Network Watcher and flow-log configuration via the supplementary module. Flow logs MUST be sent to both the Log Analytics Workspace and a storage account. The wrapper MUST provision a Storage Account for flow logs via the supplementary AVM module `avm-res-storage-storageaccount` OR accept a BYO storage account resource ID. When a BYO ID is supplied, the wrapper MUST NOT create a new storage account.

---

## Configuration Model *(mandatory)*

### Input Variable Model

The pattern MUST be fully parameterised so that consumers deploy it by modifying `terraform.tfvars` only — never by editing module source code.

- The pattern MUST provide **central root-level variables** for `location`, `enable_telemetry`, and `tags`. These are the single source of truth for region, telemetry opt-in, and base tags. All resources (core pattern, supplementary modules, resource groups) MUST inherit from these central variables unless explicitly overridden at a more specific level.
- The pattern MUST create resource group(s) for hub infrastructure. Resource groups MUST be defined as a map-based variable (keyed by a user-chosen string). Other hub resources (core pattern hub entries, supplementary modules) MUST reference their target resource group by key. The wrapper resolves the key to the resource group name/ID internally.

- The core pattern's `hub_virtual_networks` variable is a **map**, inherently supporting multi-hub topologies. The wrapper MUST preserve that capability.
- Supplementary resources (NSGs, NAT Gateways) MUST also be **map-based** variables to support multiple instances.
- All optional hub components MUST be togglable via the core pattern's `enabled_resources` flags (firewall, bastion, VPN gateway, ExpressRoute gateway, private DNS, DNS resolver). The wrapper MUST NOT reimplement feature flags that the core pattern already provides.
- Variables MUST default to AVM / core-pattern defaults wherever possible. Opinionated defaults MUST be documented in the variable's `description` and MUST be secure-by-default.
- Variables MUST NOT use overly broad types (e.g., `any`). The pattern MUST use `object({...})`, `map(...)`, `list(...)`, or scalar types with explicit type constraints.
- Sensitive values MUST be marked with `sensitive = true`.

### Key-Based Cross-Resource Referencing

The pattern MUST use map-key-based references (not raw resource IDs) for wiring resources together within the module:

- **NSGs** MUST be defined in a **flat, global map variable** at the root module level (not nested inside individual hub entries). Any hub subnet across any hub can reference any NSG by `nsg_key`. The wrapper resolves the key to the NSG resource ID internally before passing it to the core pattern. Key uniqueness is global — the same `nsg_key` MUST NOT appear twice in the map.
- **NAT Gateways** MUST follow the same flat global map pattern as NSGs. Any hub subnet can reference any NAT Gateway by `nat_gateway_key`. Key uniqueness is global.
- **Spoke VNets** for peering MUST be referenced by `spoke_key` in the peering definitions, with the spoke's `resource_id` supplied as the value.
- **Log Analytics Workspace** MUST be referenceable by key (if provisioned by the wrapper) or supplied as a BYO resource ID.
- **Flow log storage accounts** MUST be provisioned by the wrapper via the supplementary AVM module `avm-res-storage-storageaccount` OR supplied as a BYO resource ID. When a BYO ID is supplied, the wrapper MUST NOT create a new storage account. The storage account MUST be referenceable by `storage_account_key` in the flow log configuration. Key uniqueness is global.

### BYO Resource ID Fallback

For every supplementary resource the wrapper can provision, the pattern MUST also support a **Bring Your Own (BYO)** model where the consumer supplies an existing resource ID instead of having the wrapper create the resource. When a BYO resource ID is provided, the wrapper MUST NOT create a new instance of that resource.

---

## Module Usage Rules *(mandatory)*

### Core Pattern First

- The core AVM pattern module MUST be the primary engine for all resources it supports.
- Before adding a supplementary AVM resource module, the contributor MUST verify the core pattern does not already cover the capability. This verification MUST be documented.
- When the core pattern adds support for a resource this wrapper currently handles via a supplementary module, the supplementary module MUST be removed in favour of the core pattern's implementation. Migration MUST use `moved` blocks to avoid state churn.

### Supplementary Modules Only by Justified Exception

- Supplementary AVM resource modules are permitted ONLY when the core pattern does not create or manage the resource type.
- Custom `azurerm_*` resource blocks are permitted ONLY when no AVM module (pattern or resource) exists for the resource type AND the omission is documented with a tracking issue for future AVM adoption.
- AVM module versions MUST be pinned to an exact version and updated through a reviewed pull request.

### No Imperative Provisioning

- All infrastructure MUST be expressed exclusively in HashiCorp Configuration Language (HCL) executed by Terraform.
- The use of `null_resource`, `local-exec`, `remote-exec`, and any provider-level provisioner blocks is FORBIDDEN.
- External data retrieval MUST use only Terraform data sources or provider-native resources — never external scripts.
- No Bash, PowerShell, Python, or any other scripting language is permitted in the module source tree.

### No Re-Implementation of Core Pattern Features

- The wrapper MUST NOT duplicate variables, logic, or resource blocks that the core pattern already provides.
- Feature flags provided by the core pattern (e.g., `enabled_resources`) MUST be passed through, not shadowed with wrapper-level flags.

---

## Security & Reliability Expectations *(mandatory)*

### Secure-by-Default Posture

- **Least privilege**: NSG rules MUST follow the principle of least privilege. Broad wildcards (`*`) in network rules are FORBIDDEN unless explicitly justified in a pull request review and documented in the NSG rule's description attribute.
- **No public exposure by default**: Firewall, bastion, and gateway public IPs are inherently public (required for functionality). All other resources MUST NOT expose public endpoints by default. Specifically: storage accounts MUST default to `public_network_access_enabled = false`; subnets MUST default to `default_outbound_access_enabled = false`.
- **Minimum TLS**: All resources that support TLS configuration MUST default to TLS 1.2 (`min_tls_version = "TLS1_2"`). Firewall policy TLS inspection settings MUST be exposed.
- **DDoS Protection**: The pattern MUST support DDoS Protection Plan association via the core pattern's built-in support.
- **Logging and auditing**: Diagnostic settings MUST be enabled for every supplementary resource that supports them. Logs MUST be sent to the Log Analytics Workspace.

### Deterministic, Idempotent Deployments

- Given identical inputs and state, a `terraform plan` MUST produce an identical execution plan.
- Consecutive `terraform apply` runs with unchanged inputs MUST result in zero resource changes.
- The pattern MUST NOT use `terraform taint`, `terraform state rm`, or any state-manipulation commands as part of normal operation.

### Safe Updates

- Breaking changes to variable interfaces MUST follow semantic versioning.
- Zone-redundancy options MUST be exposed for firewall, bastion, and gateway resources via the core pattern's variables. NAT Gateways MUST support zone configuration.
- The core pattern's `retry` and `timeouts` variables MUST be exposed to handle transient provisioning errors.

---

## Documentation & Usability Requirements *(mandatory)*

### AVM-Style Variable Descriptions

Every input variable MUST have a non-empty `description` attribute following AVM-style conventions (see [AVM Terraform contribution guide — Terraform Coding Conventions](https://azure.github.io/Azure-Verified-Modules/contributing/terraform/)):
- Opening sentence states the purpose.
- Nested attributes are documented inline.
- Key-based referencing is explained with examples.
- Security implications are called out explicitly.

### Tooling-Generated Documentation

- All Terraform module documentation (inputs, outputs, providers, resources, sub-modules) MUST be generated by `terraform-docs`.
- AI-generated or manually curated Terraform input/output documentation is FORBIDDEN.
- Each module directory MUST contain a `README.md` with `terraform-docs` injection markers.
- `terraform-docs` MUST be executed after any variable or output change.

### Meaningful Outputs

The root module MUST export:
- All outputs from the core pattern (hub VNet IDs/names, firewall IPs, bastion IDs, DNS zone IDs, gateway IDs, etc.).
- Supplementary resource outputs (NSG IDs, NAT Gateway IDs, LAW ID, flow log IDs).
- Peering resource IDs for hub-to-spoke connections.

Every output MUST have a non-empty `description` attribute.

### Naming & Tagging

- The core pattern provides built-in naming conventions with `${location}` and `${sequence}` placeholders. The wrapper MUST expose the `default_naming_convention` variable to allow overrides.
- All resources MUST support a common `tags` variable, propagated to the core pattern, supplementary modules, and resource groups. The central `location` variable serves as the default region for all resources. The central `enable_telemetry` variable controls AVM telemetry opt-in across all modules.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Platform Team Deploys a Single-Hub Connectivity Network (Priority: P1)

A platform engineer provisions a single connectivity hub VNet with firewall, bastion, VPN gateway, and private DNS zones by supplying a `terraform.tfvars` file. The deployment uses the core pattern as the primary engine and supplements it with NSGs and a Log Analytics Workspace.

**Why this priority**: This is the foundational use case — a single hub deployment — and exercises the core pattern integration, supplementary module wiring, and key-based referencing end to end.

**Independent Test**: Can be fully tested by running `terraform plan` and `terraform apply` against a single subscription with a single hub configuration and verifying all resources are provisioned and diagnostics are enabled.

**Acceptance Scenarios**:

1. **Given** a valid `terraform.tfvars` with one hub defined in the `hub_virtual_networks` map, firewall and bastion enabled, one NSG defined by `nsg_key`, and a Log Analytics Workspace provisioned by the wrapper, **When** `terraform apply` is executed, **Then** all hub resources, the NSG, and the LAW are created, the NSG ID is associated with the designated subnet, diagnostic settings are enabled for the NSG, and `terraform plan` with unchanged inputs produces zero changes.
2. **Given** the same configuration, **When** a consumer inspects the outputs, **Then** hub VNet ID, firewall private IP, bastion ID, NSG IDs (keyed), LAW ID, and DNS zone IDs are all available.

---

### User Story 2 — Platform Team Deploys a Multi-Hub Topology (Priority: P2)

A platform engineer provisions multiple hub VNets using a single `terraform.tfvars` file with multiple entries in the `hub_virtual_networks` map. Multi-hub topologies include: (a) multi-region hubs (e.g., primary + DR across regions), and (b) same-region dual-hub (e.g., an internet egress/ingress hub and an intranet ingress hub in the same region with distinct security profiles).

**Why this priority**: Multi-hub is a common enterprise scenario and validates the map-based variable model.

**Independent Test**: Can be fully tested by running `terraform plan` with two or more hub entries and verifying each hub has independent resources, keyed outputs, and correct configuration.

**Acceptance Scenarios**:

1. **Given** a `terraform.tfvars` with two hub entries in the `hub_virtual_networks` map (e.g., `hub_internet` and `hub_intranet` in the same region), each with distinct address spaces and firewall configurations, **When** `terraform apply` is executed, **Then** two independent sets of hub resources are provisioned, and mesh peering between the hubs is established by the core pattern.
2. **Given** the same configuration with supplementary NSGs defined in the global NSG map, **When** the wrapper resolves `nsg_key` references from each hub's subnet definitions, **Then** each hub's subnets are associated with the correct NSGs. Two hubs MAY reference the same `nsg_key` if they share an NSG (same resource group / region), or reference distinct keys for isolation.
3. **Given** a dual-hub topology with a Common Services VNet (e.g., DNS Resolver), **When** two spoke peering entries reference the same spoke VNet resource ID but different `hub_key` values (`hub_internet` and `hub_intranet`), **Then** both hubs are peered to the Common Services VNet via independent bidirectional peering resources.

---

### User Story 3 — Platform Team Peers Hub to Existing Spoke VNets (Priority: P2)

A platform engineer configures hub-to-spoke peering by adding spoke entries (keyed by `spoke_key`) to the peering variable, supplying each spoke's `resource_id`.

**Why this priority**: Hub-to-spoke peering is essential for connectivity; the spoke VNets already exist and this pattern must peer to them.

**Independent Test**: Can be fully tested by supplying at least two spoke resource IDs and verifying peering resources are created with correct settings (allow forwarded traffic, allow gateway transit).

**Acceptance Scenarios**:

1. **Given** a peering variable with two entries (`spoke-app1`, `spoke-app2`) each containing a valid spoke VNet resource ID, **When** `terraform apply` is executed, **Then** four peering resources are created (hub→spoke and spoke→hub for each spoke), establishing bidirectional connectivity.
2. **Given** a spoke entry is removed from the variable, **When** `terraform plan` is executed, **Then** only the removed peering is planned for destruction; all other resources remain unchanged.

---

### User Story 4 — Platform Team Uses BYO Log Analytics Workspace (Priority: P3)

A platform engineer supplies an existing Log Analytics Workspace resource ID instead of having the wrapper create one.

**Why this priority**: Many enterprises have a centralised LAW; the BYO model avoids resource duplication.

**Independent Test**: Can be fully tested by providing a BYO LAW resource ID, confirming the wrapper does not create a new LAW, and verifying diagnostics reference the supplied ID.

**Acceptance Scenarios**:

1. **Given** a `terraform.tfvars` where the LAW variable supplies a BYO `resource_id` and no creation parameters, **When** `terraform apply` is executed, **Then** no new Log Analytics Workspace is created, and all diagnostic settings reference the supplied BYO resource ID.
2. **Given** a `terraform.tfvars` where a storage account entry in `storage_accounts` is replaced by a BYO storage account resource ID in the flow log configuration, **When** `terraform apply` is executed, **Then** no new storage account is created for flow logs, and flow logs reference the supplied BYO resource ID.

---

### User Story 5 — Platform Team Toggles Optional Components (Priority: P3)

A platform engineer disables VPN gateway and ExpressRoute gateway via the core pattern's `enabled_resources` flags, keeping only firewall and bastion active.

**Why this priority**: Not every hub needs all components; toggleability validates that the wrapper correctly passes through the core pattern's feature flags.

**Independent Test**: Can be fully tested by setting VPN and ER gateway flags to disabled and verifying that `terraform plan` does not include those resources.

**Acceptance Scenarios**:

1. **Given** a configuration where VPN gateway and ExpressRoute gateway are disabled via `enabled_resources`, **When** `terraform plan` is executed, **Then** no VPN or ExpressRoute gateway resources appear in the plan.
2. **Given** the same configuration, **When** the consumer later enables VPN gateway and re-runs `terraform apply`, **Then** the VPN gateway is added without affecting existing resources.

---

### Edge Cases

- What happens when a consumer supplies both a BYO LAW resource ID and creation parameters? The pattern MUST treat the BYO ID as authoritative and MUST NOT create a new resource. A validation rule or clear variable design MUST prevent ambiguity.
- What happens when an `nsg_key` referenced in a subnet definition does not exist in the NSG map? The pattern MUST fail at `terraform plan` time with a clear error message — not silently ignore the reference.
- What happens when the core pattern releases a new version that adds support for a resource currently handled by a supplementary module? The wrapper MUST plan migration using `moved` blocks and remove the supplementary module in a subsequent version.
- How does the pattern handle a spoke VNet resource ID that is invalid or belongs to a different tenant? The pattern relies on the Azure provider to surface authentication / authorisation errors at plan or apply time.
- What happens during partial deployment failure (e.g., hub 1 succeeds, hub 2 fails)? The pattern relies on Terraform's standard partial-apply behaviour: successfully created resources remain in state, failed resources are retried on the next `terraform apply`. No custom rollback logic is implemented.
- What happens when a hub is added or removed from the `hub_virtual_networks` map after initial deployment? Adding a hub creates new resources without affecting existing hubs. Removing a hub destroys that hub's resources. Renaming a hub key requires `moved` blocks to avoid destroy/recreate.
- What happens when a spoke VNet is deleted externally while peering resources still exist in Terraform state? The next `terraform plan` will detect the drift and plan to recreate or remove the peering resources depending on whether the spoke entry remains in the variable.
- What happens when flow log configuration is added to an existing hub after initial deployment? The pattern supports incremental addition of flow logs — adding entries to `flowlog_configuration` creates new flow log resources without affecting existing hub resources.
- What happens when both hubs reference the same `nsg_key` (cross-hub NSG sharing)? This is explicitly supported. The NSG resource is created once (in the resource group specified in its definition), and both hubs reference the same NSG resource ID. The NSG and referencing subnets MUST be in the same region.
- What happens when a NAT Gateway key is referenced from a subnet in a different region than the NAT Gateway resource? Azure requires NAT Gateways and subnets to be in the same region. The pattern relies on the Azure provider to raise an error at apply time. Consumers MUST ensure region alignment.
- What happens when the `resource_groups` map contains entries not referenced by any hub or supplementary resource? Orphaned resource groups are permitted — the pattern creates all defined resource groups regardless of references. This allows consumers to pre-create resource groups for future use.
- What happens when two hubs define overlapping address spaces? The pattern does not validate address space uniqueness. Overlapping address spaces will cause Azure-level peering failures. Consumers are responsible for address space planning.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The pattern MUST invoke the AVM core pattern module `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` as its primary engine for all resources that module supports.
- **FR-002**: The pattern MUST support multi-hub topologies via the core pattern's map-based `hub_virtual_networks` variable. Supported topologies include: (a) multi-region hubs (e.g., primary + DR), (b) same-region dual-hub (e.g., internet egress/ingress hub + intranet ingress hub with distinct address spaces and firewall configurations), and (c) single-hub. Each hub entry is independently configurable for firewall, bastion, gateways, and DNS.
- **FR-003**: The pattern MUST provision Network Security Groups via the supplementary AVM module `avm-res-network-networksecuritygroup` and pass their IDs to the core pattern for subnet association. Note: AzureFirewallSubnet, AzureBastionSubnet, and GatewaySubnet do not support user-defined NSGs; the core pattern manages security for these subnet types internally. Only user-defined subnets may reference `nsg_key`.
- **FR-004**: The pattern MUST provision NAT Gateways via the supplementary AVM module `avm-res-network-natgateway` and pass their IDs to the core pattern for subnet association.
- **FR-005**: The pattern MUST provision a Log Analytics Workspace via the supplementary AVM module `avm-res-operationalinsights-workspace` OR accept a BYO resource ID. When a BYO ID is supplied, the pattern MUST NOT create a new workspace.
- **FR-006**: The pattern MUST provision Network Watcher and flow-log configuration via the supplementary AVM module `avm-res-network-networkwatcher`.
- **FR-007**: The pattern MUST support bidirectional VNet peering (hub→spoke and spoke→hub) to existing spoke VNets, defined via a map variable keyed by `spoke_key`. Both peering resources MUST be created from a single configuration entry.
- **FR-008**: The pattern MUST use key-based cross-resource referencing (`nsg_key`, `nat_gateway_key`, `spoke_key`) for wiring supplementary resources to hub subnets and peering definitions.
- **FR-009**: The pattern MUST enable diagnostic settings for every supplementary resource that supports them — specifically: Network Security Groups, NAT Gateways, and User-Assigned Managed Identities — sending logs to the Log Analytics Workspace.
- **FR-010**: The pattern MUST expose all core pattern feature flags (`enabled_resources`) to consumers without re-implementing them at the wrapper level.
- **FR-011**: The pattern MUST expose the core pattern's `retry` and `timeouts` variables to consumers.
- **FR-012**: The pattern MUST expose the `default_naming_convention` variable from the core pattern to allow naming overrides.
- **FR-013**: The pattern MUST support a common `tags` variable propagated to the core pattern and all supplementary modules.
- **FR-014**: The pattern MUST export all outputs from the core pattern plus supplementary resource outputs (NSG IDs, NAT Gateway IDs, LAW ID, flow log IDs, peering IDs).
- **FR-015**: Every output MUST have a non-empty `description` attribute.
- **FR-016**: Every input variable MUST have a non-empty `description` following AVM-style conventions, explicit type constraints (no `any`), and secure-by-default values.
- **FR-017**: The pattern MUST pin Terraform version to `>= 1.13, < 2.0`, `azurerm` provider to `~> 4.0`, `azapi` provider to `~> 2.0`, and `random` provider to `~> 3.0`. The `random` provider is used in examples for unique naming.
- **FR-018**: AVM module versions MUST be pinned to an exact version.
- **FR-019**: All module documentation MUST be generated by `terraform-docs` with injection markers in each `README.md`.
- **FR-020**: The pattern MUST contain zero `null_resource`, `local-exec`, `remote-exec`, or provisioner blocks.
- **FR-021**: The pattern MUST contain zero Bash, PowerShell, Python, or other scripting language files in the module source tree.
- **FR-022**: The pattern MUST support zone-redundancy configuration for firewall, bastion, gateway, and NAT Gateway resources.
- **FR-023**: Sensitive input values MUST be marked with `sensitive = true`.
- **FR-024**: The pattern MUST fail with a clear error at `terraform plan` time when an `nsg_key` or `nat_gateway_key` referenced in a subnet definition does not exist in the corresponding map variable. Validation MUST be implemented using Terraform `precondition` blocks or `validation` blocks on variables, not via runtime errors.
- **FR-025**: When the wrapper creates a new Log Analytics Workspace, the default retention period MUST be 30 days. The retention value MUST be overridable via the LAW variable.
- **FR-026**: The wrapper MUST provision a Storage Account for flow logs via the supplementary AVM module `avm-res-storage-storageaccount` OR accept a BYO storage account resource ID. When a BYO ID is supplied, the wrapper MUST NOT create a new storage account. Flow logs MUST be sent to both the LAW and the storage account.
- **FR-027**: The pattern MUST create resource group(s) for hub infrastructure, defined as a map-based variable. Hub resources MUST reference their target resource group by key (not by raw name or ID).
- **FR-028**: The pattern MUST provide central root-level variables for `location`, `enable_telemetry`, and `tags`. All resources MUST inherit from these unless explicitly overridden at a more specific level.
- **FR-029**: The central `enable_telemetry` variable MUST be propagated to the core pattern and all supplementary AVM modules that support it.
- **FR-030**: Every parameter exposed by each AVM module (core pattern and supplementary) MUST be passthrough from root-level variables / `terraform.tfvars`. No AVM module parameter may be hardcoded in `main.tf` unless it is a computed or derived value (resolved resource ID, merged tags, defaulted location).
- **FR-031**: The pattern MUST expose the core pattern's `hub_and_spoke_networks_settings` variable to allow consumers to configure shared settings across hubs, including DDoS Protection Plan association and mesh peering control (`mesh_peering_enabled`).
- **FR-032**: The pattern MUST support peering hub VNets to a common services VNet (e.g., containing a DNS Resolver) by allowing multiple spoke peering entries that reference the same spoke VNet resource ID with different `hub_key` values.
- **FR-033**: Flow log configuration MUST support optional traffic analytics enablement. When traffic analytics is enabled, consumers MUST be able to configure the `interval_in_minutes` parameter. Traffic analytics MUST be disabled by default.
- **FR-034**: When a consumer supplies both a BYO resource ID and creation parameters for the same resource type (LAW, storage account), the BYO resource ID MUST take precedence. The wrapper MUST NOT create a new instance. The pattern SHOULD implement a validation rule to warn or prevent this conflicting configuration.
- **FR-035**: The pattern MUST provision User-Assigned Managed Identities via the supplementary AVM module `avm-res-managedidentity-userassignedidentity` when required for resources that need identity-based access (e.g., storage account access for flow logs). Managed identities MUST be defined in a flat global map variable keyed by a user-chosen string.
- **FR-036**: The pattern MUST provision RBAC Role Assignments via the supplementary AVM module `avm-res-authorization-roleassignment` to grant managed identities access to resources they need (e.g., Storage Blob Data Contributor on flow log storage accounts). Role assignments MUST be defined in a flat global map variable.
- **FR-037**: The pattern MUST include AVM-compliant example directories under `examples/`. Each example MUST be self-contained (zero required input variables), deployable via `terraform apply` without external dependencies, and include a `README.md` auto-generated by `terraform-docs` with a `_header.md` file. The root module additionally uses a `_footer.md` file for the Microsoft data collection notice. The `default/` example is mandatory.

### Key Entities

- **Resource Group**: The Azure resource container for hub infrastructure. Defined in a map variable keyed by a user-chosen string. Other resources reference the RG by this key. Created by the wrapper. Attributes: name, location (defaults to central `location` variable), tags (defaults to central `tags` variable).
- **Hub Virtual Network**: The central network resource with address spaces, DNS servers, DDoS protection, and subnets. Identified by a user-chosen map key in `hub_virtual_networks`. References its resource group by key. Relationships: contains subnets, associated with firewall, bastion, gateways, and DNS zones.
- **Network Security Group**: A security boundary for subnet traffic filtering. Defined in a flat global map at root level; identified by `nsg_key`. Any hub subnet across any hub can reference an NSG by key, enabling cross-hub reuse. Relationship: associated with hub subnets by key reference.
- **NAT Gateway**: Provides outbound internet connectivity for subnets. Defined in a flat global map at root level; identified by `nat_gateway_key`. Same cross-hub reuse semantics as NSGs. Relationship: associated with hub subnets by key reference.
- **Spoke VNet Peering**: A bidirectional connectivity link between hub and an existing spoke VNet. Identified by `spoke_key`. Each entry creates two Azure peering resources (hub→spoke and spoke→hub). Relationship: references the spoke's `resource_id`.
- **Log Analytics Workspace**: The observability sink for diagnostic logs. Can be provisioned by the wrapper (default retention: 30 days, overridable) or supplied as BYO. Relationship: consumed by all diagnostic settings.
- **Network Watcher / Flow Log**: Network-level observability for traffic analysis. Relationship: observes NSG flows, sends to LAW and to a storage account (provisioned by the wrapper or BYO).
- **Storage Account (Flow Logs)**: Storage destination for flow log data. Defined in a map variable (or BYO). Identified by `storage_account_key`. Relationship: consumed by flow log configuration.

---

## Success Criteria *(mandatory)*

### Traceability

All functional requirements (FR-xxx) map to one or more success criteria (SC-xxx). User stories validate FRs through acceptance scenarios. The mapping is:
- SC-001 validates FR-001, FR-003, FR-005, FR-009, FR-027, FR-028, FR-030
- SC-002 validates FR-002, FR-014, FR-031
- SC-003 validates FR-001 through FR-029 (idempotency is a cross-cutting concern)
- SC-004 validates FR-017, FR-019, FR-020, FR-021
- SC-005 validates FR-020, FR-021
- SC-006 validates FR-001, FR-003, FR-004, FR-005, FR-006, FR-035, FR-036
- SC-007 validates FR-008
- SC-008 validates FR-009
- SC-009 validates FR-016, FR-023
- SC-010 validates FR-014, FR-015

### Measurable Outcomes

- **SC-001**: A platform engineer can deploy a complete single-hub connectivity network (hub VNet, firewall, bastion, NSGs, LAW, DNS zones) by providing only a `terraform.tfvars` file, without modifying module source code.
- **SC-002**: A platform engineer can deploy a multi-hub topology (two or more hubs) from a single configuration, with each hub independently addressable in outputs. Specifically, the following outputs MUST be keyed by hub key: `hub_virtual_network_ids`, `hub_virtual_network_names`, `firewall_private_ip_addresses`, `firewall_resource_names`, `bastion_host_dns_names`.
- **SC-003**: `terraform plan` with unchanged inputs produces zero resource changes (idempotency verified).
- **SC-004**: All five mandatory quality gates pass with zero errors: `terraform fmt -check -recursive`, `terraform validate`, `terraform plan`, `terraform-docs` freshness, and linting.
- **SC-005**: Zero `null_resource`, `local-exec`, `remote-exec`, provisioner, or scripting language artifacts exist in the module source tree.
- **SC-006**: Every supplementary module has a documented justification in the §Architecture section's supplementary module table confirming the core pattern does not support the capability.
- **SC-007**: Key-based cross-resource referencing is used throughout; no raw resource IDs appear in consumer-facing variable interfaces where key-based wiring is possible.
- **SC-008**: Diagnostic settings are enabled for every supplementary resource that supports them.
- **SC-009**: All input variables have explicit type constraints, non-empty descriptions, and secure-by-default values. No variable uses type `any`. Secure-by-default means: `public_network_access_enabled = false`, `default_outbound_access_enabled = false`, `min_tls_version = "TLS1_2"` where applicable.
- **SC-010**: All outputs have non-empty descriptions and expose the IDs/attributes required by documented consumer contracts.

---

## Assumptions

- The core AVM pattern module `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` is available on the Terraform Registry and supports all resources documented in its current release. The pattern targets version **0.16.14** specifically; feature availability is locked to this version's capabilities.
- Consumers have Terraform `>= 1.13, < 2.0` installed and configured with the `azurerm ~> 4.0` and `azapi ~> 2.0` providers authenticated to the target Azure subscription(s).
- For cross-subscription peering (hub and spoke in different subscriptions), the deploying identity MUST have Network Contributor (or equivalent) RBAC on both subscriptions. Multi-subscription authentication is handled via standard Terraform provider aliasing.
- Spoke VNets referenced for peering already exist and are accessible from the hub subscription. The deploying identity MUST have Network Contributor RBAC on both the hub and spoke VNets to create bidirectional peering resources. For Resource Group operations, Contributor on the target resource group is required. For role assignments, User Access Administrator or equivalent is required.
- CI/CD pipelines that invoke this pattern are responsibility of the consuming team and are not governed by this specification.
- `terraform-docs` version `>= 0.18.0` is available in the contributor's development environment for documentation generation.
- Network Watcher is managed by the supplementary module (`avm-res-network-networkwatcher`). If Azure automatic Network Watcher provisioning is disabled on the subscription, the supplementary module handles creation. The pattern does not assume a pre-existing Network Watcher.
- Standard Azure provider authentication mechanisms (service principal, managed identity, Azure CLI) are used; the pattern does not implement custom authentication logic.
- The pattern does not impose hard upper bounds on the number of hubs, NSGs, NAT Gateways, or spoke peerings. Practical limits are governed by Azure subscription quotas, Terraform state performance, and provider API rate limits. For very large deployments (10+ hubs, 50+ NSGs), consumers should consider splitting across multiple pattern invocations.
- Terraform parallelism and concurrency are controlled by the consumer's `terraform apply -parallelism` setting and the core pattern's internal `retry`/`timeouts` configuration. No pattern-level parallelism constraints are imposed.
