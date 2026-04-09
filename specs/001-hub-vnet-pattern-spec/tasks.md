# Tasks: PLZ Connectivity Hub VNet Pattern

**Input**: Design documents from `/specs/001-hub-vnet-pattern-spec/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested â€” test tasks are omitted. Validation tasks (terraform fmt/validate/plan) are included in the Polish phase.

**Organization**: Tasks are grouped by implementation phase for the resource module decomposition architecture.

## Resource Module Decomposition Amendment

**Date**: 2026-04-09

The task list has been rewritten for the new architecture using individual AVM resource modules. Previous tasks related to the monolithic `hub_and_spoke_vnet_pattern` core module are obsolete.

### Current Module Implementation Status

| Module | Status | Notes |
|--------|--------|-------|
| `module.resource_group` | âœ… Implemented | v0.2.2 â€” full passthrough |
| `module.network_security_group` | âœ… Implemented | v0.5.1 â€” full passthrough |
| `module.route_table` | âœ… Implemented | v0.5.0 â€” full passthrough |
| `module.nat_gateway` | âœ… Implemented | v0.3.2 â€” full passthrough |
| `module.virtual_network` | âœ… Implemented | v0.17.1 â€” full passthrough with key resolution |
| `module.private_dns_zone` | âœ… Implemented | v0.5.0 â€” full passthrough with VNet link key resolution |
| `module.private_dns_zone_link` | âœ… Implemented | v0.5.0 â€” full passthrough with VNet key resolution |
| `module.network_watcher` | âœ… Implemented | v0.3.2 â€” full passthrough |
| `module.virtual_network_gateway` | â¬œ Stub | v0.16.14 â€” needs full passthrough implementation |
| `module.public_ip` | â¬œ Stub | v0.2.1 â€” needs full passthrough implementation |
| `module.firewall_policy` | â¬œ Stub | v0.3.4 â€” needs full passthrough implementation |
| `module.firewall` | â¬œ Stub | v0.4.0 â€” needs full passthrough implementation |

## Format: `[ID] [P?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions

- Root module files at repository root: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `terraform.tf`
- Examples under `examples/<name>/`
- Docs: `_header.md`, `_footer.md`, `.terraform-docs.yml` at root and example levels

---

## Phase 1: Stub Module Implementation

**Purpose**: Implement the 4 stub modules with full parameter passthrough from root-level variables

### Virtual Network Gateway Module

- [x] T001 Add `virtual_network_gateways` variable in `variables.tf` â€” flat global map with explicit type constraints matching `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm//modules/virtual-network-gateway` module interface. Fields: `name`, `resource_group_key`, `location?`, VPN/ExpressRoute config, IP configurations, local network gateways, BGP settings, point-to-site config, etc. Include `lock?`, `role_assignments?`, `tags?`
- [x] T002 Implement `module "virtual_network_gateway"` passthrough in `main.tf` â€” replace stub comment with full parameter passthrough from `var.virtual_network_gateways[each.key].*`. Resolve `resource_group_key` via `local.resource_group_names`. Apply `coalesce(each.value.location, var.location)` for location defaulting. Merge tags via `merge(var.tags, each.value.tags)`. Resolve `managed_identity_key` in role assignments
- [x] T003 Add `virtual_network_gateway_resource_ids` local in `locals.tf` and output in `outputs.tf`

### Public IP Module

- [x] T004 [P] Add `public_ips` variable in `variables.tf` â€” flat global map matching `Azure/avm-res-network-publicipaddress/azurerm` module interface. Fields: `name`, `resource_group_key`, `location?`, `allocation_method?`, `sku?`, `sku_tier?`, `zones?`, `ip_version?`, `domain_name_label?`, `ddos_protection_mode?`, `ddos_protection_plan_id?`, `idle_timeout_in_minutes?`, `ip_tags?`, `public_ip_prefix_id?`, `reverse_fqdn?`, `edge_zone?`, `diagnostic_settings?`, `lock?`, `role_assignments?`, `tags?`
- [x] T005 [P] Implement `module "public_ip"` passthrough in `main.tf` â€” replace stub comment with full parameter passthrough. Resolve `resource_group_key`. Apply location/tag defaulting
- [x] T006 [P] Add `public_ip_resource_ids` local in `locals.tf` and output in `outputs.tf`

### Firewall Policy Module

- [x] T007 [P] Add `firewall_policies` variable in `variables.tf` â€” flat global map matching `Azure/avm-res-network-firewallpolicy/azurerm` module interface. Fields: `name`, `resource_group_key`, `location?`, `sku?`, `base_policy_id?`, `dns?`, `explicit_proxy?`, `identity?`, `insights?`, `intrusion_detection?`, `private_ip_ranges?`, `sql_redirect_allowed?`, `threat_intelligence_mode?`, `threat_intelligence_allowlist?`, `tls_certificate?`, `auto_learn_private_ranges_enabled?`, `lock?`, `role_assignments?`, `tags?`
- [x] T008 [P] Implement `module "firewall_policy"` passthrough in `main.tf` â€” replace stub comment with full parameter passthrough. Resolve `resource_group_key`. Apply location/tag defaulting
- [x] T009 [P] Add `firewall_policy_resource_ids` local in `locals.tf` and output in `outputs.tf`

### Firewall Module

- [x] T010 Add `firewalls` variable in `variables.tf` â€” flat global map matching `Azure/avm-res-network-azurefirewall/azurerm` module interface. Fields: `name`, `resource_group_key`, `location?`, `sku_name?`, `sku_tier?`, `firewall_policy_key?` (or `firewall_policy_id`), `ip_configuration`, `management_ip_configuration?`, `zones?`, `private_ip_ranges?`, `virtual_hub?`, `diagnostic_settings?`, `lock?`, `role_assignments?`, `tags?`. Support key-based reference to `firewall_policies` via `firewall_policy_key`
- [x] T011 Implement `module "firewall"` passthrough in `main.tf` â€” replace stub comment with full parameter passthrough. Resolve `resource_group_key`, `firewall_policy_key` â†’ `local.firewall_policy_resource_ids[key]`. Apply location/tag defaulting
- [x] T012 Add `firewall_resource_ids` local in `locals.tf` and output in `outputs.tf`

**Checkpoint**: All 4 stub modules fully implemented with variables, main.tf passthrough, locals, and outputs.

---

## Phase 2: Variables & Locals Cleanup

**Purpose**: Update existing variables and locals to align with the decomposed architecture

- [x] T013 Remove old `hub_virtual_networks` variable from `variables.tf` (if still present) â€” replaced by `virtual_networks`
- [x] T014 Remove old `hub_and_spoke_networks_settings`, `default_naming_convention`, `default_naming_convention_sequence`, root-level `timeouts` variables from `variables.tf` (if still present)
- [x] T015 Update `locals.tf` â€” remove references to `module.hub_and_spoke_vnet_pattern`. Update `vnet_resource_ids` to source from `module.virtual_network`. Update `firewall_private_ips` to source from `module.firewall`. Add `rt_resource_ids`, `firewall_policy_resource_ids`, `public_ip_resource_ids`, `virtual_network_gateway_resource_ids` locals as needed
- [x] T016 Remove commented-out `module "hub_and_spoke_vnet_pattern"` block from `main.tf`

**Checkpoint**: Clean variables and locals â€” no references to the old core pattern module.

---

## Phase 3: Outputs Update

**Purpose**: Update outputs to reference individual resource modules

- [x] T017 Update `outputs.tf` â€” replace all `module.hub_and_spoke_vnet_pattern.*` references with individual module outputs. Add new outputs: `virtual_network_ids`, `route_table_ids`, `firewall_ids`, `firewall_policy_ids`, `public_ip_ids`, `virtual_network_gateway_ids`, `private_dns_zone_ids`. Remove old core-pattern-specific outputs (`hub_virtual_network_names`, `firewall_resource_names`, `bastion_host_dns_names`, `route_tables_firewall`, `route_tables_user_subnets`)

**Checkpoint**: All outputs sourced from individual resource modules.

---

## Phase 4: Validation & Key Resolution

**Purpose**: Add precondition validations for key-based cross-references

- [x] T018 Add/update precondition validations in `main.tf` â€” validate `resource_group_key` references across all modules, `network_security_group_key` in VNet subnets, `route_table_key` in VNet subnets, `virtual_network_key` in DNS zone links, `firewall_policy_key` in firewalls
- [x] T019 Verify key resolution completeness in `locals.tf` â€” every key-based reference has a corresponding lookup map

**Checkpoint**: All cross-references validated at plan time.

---

## Phase 5: Examples Rewrite

**Purpose**: Rewrite examples to use the new flat variable interface

- [x] T020 [P] Rewrite `examples/default/variables.tf` and `terraform.tfvars` â€” use individual resource variables instead of `hub_virtual_networks`
- [x] T021 [P] Rewrite `examples/default/main.tf` and `outputs.tf` â€” update module call to pass new variables
- [x] T022 [P] Rewrite `examples/full-dual-hub/variables.tf` and `terraform.tfvars` â€” decompose dual-hub topology into individual resources
- [x] T023 [P] Rewrite `examples/full-dual-hub/main.tf` and `outputs.tf` â€” update module call

**Checkpoint**: Both examples use the new variable interface.

---

## Phase 6: Documentation & Polish

**Purpose**: Regenerate docs, validate, run quality checks

- [x] T024 Update root `variables.tf` descriptions â€” ensure all new/updated variables have AVM-style descriptions with nested attribute documentation
- [x] T025 Run `terraform fmt -check -recursive` on root + all examples â€” fix any formatting issues
- [x] T026 Run `terraform validate` on root module + all examples â€” fix any validation errors
- [x] T027 Run `terraform-docs .` for root + both examples â€” regenerate all README files
- [x] T028 Passthrough completeness audit â€” verify every module block has zero hardcoded values
- [x] T029 Constitution compliance self-assessment â€” verify all 8 principles satisfied

**Checkpoint**: All quality gates pass.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Stub Implementation)**: No dependencies â€” can start immediately. T004-T009 can run in parallel with T001-T003 (different modules). T010-T012 depend on T007-T009 (firewall needs firewall_policy key resolution)
- **Phase 2 (Cleanup)**: Depends on Phase 1 â€” all stubs must be implemented before removing old variables
- **Phase 3 (Outputs)**: Depends on Phase 2 â€” outputs reference the cleaned-up modules
- **Phase 4 (Validation)**: Depends on Phase 1 â€” need all modules present for preconditions
- **Phase 5 (Examples)**: Depends on Phases 1-3 â€” need complete module interface
- **Phase 6 (Polish)**: Depends on all previous phases

### Parallel Opportunities

```
Phase 1:
  â”Œâ”€ T001-T003 (VNet Gateway)
  â”œâ”€ T004-T006 (Public IP)         â† parallel
  â”œâ”€ T007-T009 (Firewall Policy)   â† parallel
  â””â”€ T010-T012 (Firewall)          â† after T007-T009

Phase 2: T013-T016 (sequential)

Phase 3: T017 (single task)

Phase 4: T018-T019 (sequential)

Phase 5:
  â”Œâ”€ T020-T021 (default example)    â† parallel
  â””â”€ T022-T023 (full-dual-hub)      â† parallel

Phase 6: T024-T029 (sequential)
```

> **Note**: The original task list is preserved below for historical context.

## Previous Tasks (Historical â€” All Completed)

The following tasks were completed under the previous architecture using the core pattern module. They are now obsolete but preserved for reference.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Root module files at repository root: `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `terraform.tf`
- Examples under `examples/<name>/`
- Docs: `_header.md`, `_footer.md`, `.terraform-docs.yml` at root and example levels

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization â€” evaluate starter code, remove duplicates with core pattern, update module versions

- [x] T001 Retain `module "route_table"` per research.md R-010 â€” verify it serves additional custom route tables beyond core pattern scope. Update module version if needed and ensure passthrough variables match latest AVM interface
- [x] T002 Retain `module "private_dns_zone"` per research.md R-010 â€” verify it serves additional DNS zone needs beyond core pattern scope (e.g., zones not covered by core pattern's private-link DNS). Update module version if needed and ensure passthrough variables match latest AVM interface
- [x] T003 Retain `module "private_dns_zone_link"` per research.md R-010 â€” serves BYO DNS zone VNet links beyond core pattern scope. Update module version if needed and ensure passthrough variables match latest AVM interface
- [x] T004 Update `module "managed_identity"` version from `"0.4.0"` to `"0.5.0"` in `main.tf`
- [x] T005 Update `module "storage_account"` version from `"0.6.7"` to `"0.6.8"` in `main.tf`
- [x] T006 Clean up stale locals in `locals.tf`: remove `key_vault_resource_ids` (no key_vault module exists). Retain `rt_resource_ids`, `private_dns_zone_resource_ids`, and `pe_dns_zone_ids` â€” these serve retained modules per R-010

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add core pattern module call and passthrough variables â€” MUST complete before ANY user story work

**âš ï¸ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Add `module "hub_and_spoke_vnet_pattern"` block in `main.tf` replacing the TODO placeholder, with `source = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"`, `version = "0.16.14"`, and all inputs passthrough from root variables (`hub_virtual_networks`, `hub_and_spoke_networks_settings`, `default_naming_convention`, `default_naming_convention_sequence`, `enable_telemetry`, `tags`, `timeouts`). This task creates the complete module call INCLUDING the key-resolution `for` expressions that resolve `nsg_key` â†’ `local.nsg_resource_ids[nsg_key]` and `nat_gateway_key` â†’ `local.nat_gateway_resource_ids[nat_gateway_key]` in subnet definitions (per data-model.md Â§Key Resolution Pattern)
- [x] T008 Add core pattern passthrough variables in `variables.tf` replacing the TODO placeholder: `hub_virtual_networks` (map-based, matching core pattern type signature), `hub_and_spoke_networks_settings`, `default_naming_convention`, `default_naming_convention_sequence`, `timeouts`
- [x] T009 Add core pattern output lookups in `locals.tf`: `vnet_resource_ids` from `module.hub_and_spoke_vnet_pattern.virtual_network_resource_ids`, `firewall_private_ips` from `module.hub_and_spoke_vnet_pattern.firewall_private_ip_addresses`
- [x] T010 [P] Add `nat_gateways` variable in `variables.tf` â€” flat global map with fields: `name`, `resource_group_key`, `location?`, `sku_name?`, `idle_timeout_in_minutes?`, `zones?`, `public_ip_configuration?`, `diagnostic_settings?`, `lock?`, `role_assignments?`, `tags?`, `enable_telemetry?` â€” following the same pattern as `network_security_groups`
- [x] T011 [P] Add `module "nat_gateway"` block in `main.tf` with `source = "Azure/avm-res-network-natgateway/azurerm"`, `version = "0.3.2"`, `for_each = var.nat_gateways`, all parameters passthrough from `var.nat_gateways[each.key].*` including `diagnostic_settings` (FR-009), resource group resolved from `local.resource_group_names[each.value.resource_group_key]`
- [x] T012 Add `nat_gateway_resource_ids` local in `locals.tf`: `{ for key, mod in module.nat_gateway : key => mod.resource_id }`
- [x] T013 Add `spoke_virtual_networks` variable in `variables.tf` â€” map keyed by `spoke_key` with fields: `spoke_vnet_resource_id`, `hub_key`, `allow_forwarded_traffic?`, `allow_gateway_transit?`, `use_remote_gateways?`, `allow_virtual_network_access?`
- [x] T014 Add bidirectional VNet peering resources in `main.tf`: `azurerm_virtual_network_peering.hub_to_spoke` and `azurerm_virtual_network_peering.spoke_to_hub` with `for_each = var.spoke_virtual_networks`, hub VNet ID resolved from `local.vnet_resource_ids[each.value.hub_key]` (justified: no standalone AVM peering module exists per research.md R-003)

**Checkpoint**: Foundation ready â€” core pattern integrated, NAT GW module added, peering resources defined. User story implementation can now begin in parallel.

---

## Phase 3: User Story 1 â€” Single-Hub Deployment (Priority: P1) ðŸŽ¯ MVP

**Goal**: A platform engineer deploys a complete single-hub connectivity network (hub VNet, firewall, bastion, NSGs, LAW, DNS zones) by providing only a `terraform.tfvars` file.

**Independent Test**: Run `terraform plan` and `terraform apply` with a single hub, one NSG, one LAW, firewall + bastion enabled. Verify all resources created, NSG associated with subnet, diagnostics enabled, idempotent re-plan.

### Implementation for User Story 1

- [x] T015 [US1] Verify NSG key resolution in `module.hub_and_spoke_vnet_pattern` (created in T007) â€” code review confirms `nsg_key` values resolve correctly via `local.nsg_resource_ids` in the `for` expression. Add integration test: `terraform plan` with one NSG + one subnet referencing it must show correct association
- [x] T016 [US1] Add validation for `nsg_key` references in `variables.tf` or as `precondition` blocks in `main.tf` â€” pattern MUST fail at `terraform plan` time when a referenced `nsg_key` does not exist in `var.network_security_groups` (FR-024)
- [x] T017 [US1] Populate `outputs.tf` with core pattern passthrough outputs: `hub_virtual_network_ids`, `hub_virtual_network_names`, `firewall_private_ip_addresses`, `firewall_resource_names`, `bastion_host_dns_names`, `route_tables_firewall`, `route_tables_user_subnets`, `private_dns_zone_resource_ids` â€” all keyed by hub key with non-empty `description` attributes
- [x] T018 [US1] Populate `outputs.tf` with supplementary resource outputs: `resource_group_ids`, `resource_group_names`, `nsg_resource_ids`, `log_analytics_workspace_id`, `storage_account_resource_ids`, `managed_identity_principal_ids` â€” all with non-empty `description` attributes. Note: `storage_account_resource_ids` and `managed_identity_principal_ids` may produce empty maps until US4 features are configured â€” this is expected; defining all outputs in US1 prevents downstream breakage
- [x] T019 [US1] Verify `module "log_analytics_workspace"` defaults: ensure `retention_in_days` defaults to `30` in `var.log_analytics_workspace_configuration` type definition (FR-025), confirm BYO precedence logic in `locals.tf` is correct (FR-034)

**Checkpoint**: Single-hub deployment fully functional â€” MVP deliverable.

---

## Phase 4: User Story 2 â€” Multi-Hub / Dual-Hub Topology (Priority: P2)

**Goal**: A platform engineer deploys multiple hub VNets (e.g., internet egress/ingress hub + intranet ingress hub in the same region) using a single `terraform.tfvars` with multiple entries in `hub_virtual_networks`.

**Independent Test**: Run `terraform plan` with two hub entries in `hub_virtual_networks`, distinct address spaces, distinct firewall configs. Verify two independent hub resource sets, mesh peering between hubs, correct NSG key resolution per hub.

### Implementation for User Story 2

- [x] T020 [US2] Verify NAT Gateway key resolution in `module.hub_and_spoke_vnet_pattern` (created in T007) â€” code review confirms `nat_gateway_key` values resolve correctly via `local.nat_gateway_resource_ids` in the `for` expression. Add integration test: `terraform plan` with one NAT GW + one subnet referencing it must show correct association
- [x] T021 [US2] Add validation for `nat_gateway_key` references in `variables.tf` or as `precondition` blocks in `main.tf` â€” pattern MUST fail at `terraform plan` time when a referenced `nat_gateway_key` does not exist in `var.nat_gateways` (FR-024)
- [x] T022 [US2] Add `nat_gateway_resource_ids` output in `outputs.tf` with non-empty `description` attribute
- [x] T023 [US2] Verify core pattern mesh peering works correctly when two hub entries exist in `hub_virtual_networks` â€” the core pattern's `hub_and_spoke_networks_settings` controls `mesh_peering_enabled` (FR-031). Pass: `terraform plan` with two hub entries and `mesh_peering_enabled = true` shows peering resources between hubs. Fail: missing peering resources or plan errors with dual-hub config

**Checkpoint**: Dual-hub topology functional â€” internet + intranet hubs independently deployed with cross-hub mesh peering.

---

## Phase 5: User Story 3 â€” Hub-to-Spoke Peering (Priority: P2)

**Goal**: A platform engineer peers hub VNets to existing spoke VNets by adding spoke entries to the peering variable.

**Independent Test**: Supply two spoke VNet resource IDs in `var.spoke_virtual_networks`. Verify four peering resources created (hubâ†’spoke and spokeâ†’hub for each). Remove one entry and verify only that peering is destroyed.

### Implementation for User Story 3

- [x] T024 [US3] Add `spoke_peering_ids` output in `outputs.tf` â€” map of `spoke_key â†’ { hub_to_spoke_id, spoke_to_hub_id }` with non-empty `description` attribute
- [x] T025 [US3] Verify peering resource attribute passthrough: `allow_forwarded_traffic`, `allow_gateway_transit`, `use_remote_gateways`, `allow_virtual_network_access` all pass through from `var.spoke_virtual_networks[each.key].*` in `main.tf`

**Checkpoint**: Hub-to-spoke peering functional â€” bidirectional peering resources created and destroyed cleanly.

---

## Phase 6: User Story 4 â€” BYO Log Analytics Workspace (Priority: P3)

**Goal**: A platform engineer supplies an existing LAW resource ID instead of having the wrapper create one.

**Independent Test**: Provide a BYO LAW resource ID, confirm no new LAW is created, verify diagnostics reference the BYO ID.

### Implementation for User Story 4

- [x] T026 [US4] (Code Review) Verify BYO LAW precedence logic in `locals.tf` â€” when `var.byo_log_analytics_workspace.resource_id` is provided, `default_log_analytics_workspace_resource_id` must resolve to the BYO ID and `module.log_analytics_workspace` must not be created (FR-034)
- [x] T027 [US4] (Code Review) Verify BYO storage account support for flow logs â€” when a flow log entry supplies `storage_account.resource_id` instead of `storage_account.key`, the wrapper must use the BYO ID directly (FR-026)
- [x] T028 [US4] Add `network_watcher_id` output in `outputs.tf` with non-empty `description` attribute

**Checkpoint**: BYO resource model functional â€” LAW and storage account BYO paths verified.

---

## Phase 7: User Story 5 â€” Toggle Optional Components (Priority: P3)

**Goal**: A platform engineer disables VPN/ER gateways via `enabled_resources` flags, keeping only firewall and bastion.

**Independent Test**: Set VPN and ER gateway flags to disabled in `hub_virtual_networks` entry's `enabled_resources`. Verify `terraform plan` does not include gateway resources.

### Implementation for User Story 5

- [x] T029 [US5] Verify `enabled_resources` flags passthrough from `var.hub_virtual_networks` to `module.hub_and_spoke_vnet_pattern` in `main.tf` â€” code review confirms the wrapper does NOT shadow or reimplement these flags, and `enabled_resources` flows through the `for` expression without transformation (FR-010). Pass: no wrapper-level `enabled_resources` variable exists
- [x] T030 [US5] Verify `retry` and `timeouts` variables passthrough from `var.timeouts` to `module.hub_and_spoke_vnet_pattern` (FR-011). Pass: `module.hub_and_spoke_vnet_pattern.timeouts` equals `var.timeouts` with no wrapper transformation

**Checkpoint**: Feature flag toggling verified â€” all core pattern flags pass through without wrapper interference.

---

## Phase 8: Examples (AVM Convention)

**Purpose**: Create self-contained, deployable example directories following AVM conventions

- [x] T031 [P] Create `examples/.terraform-docs.yml` â€” shared terraform-docs config for all examples (AVM standard format)
- [x] T032 [P] Create `examples/README.md` â€” boilerplate instructions for running examples

### default/ Example (Minimal Single-Hub)

- [x] T033 [P] Create `examples/default/main.tf` â€” `terraform{}` block (required_version >= 1.13, < 2.0; azurerm ~> 4.0; random ~> 3.0), `provider "azurerm" { features {} }`, random region + naming modules, `module "hub"` call with `source = "../../"` â€” minimal config: one RG, one hub VNet (hub_sea) with firewall + bastion, one NSG, LAW created by wrapper, `enable_telemetry = false`, region `southeastasia`, zero required input variables
- [x] T034 [P] Create `examples/default/outputs.tf` â€” key outputs: `hub_virtual_network_ids`, `firewall_private_ip_addresses`, `resource_group_ids`, `nsg_resource_ids`
- [x] T035 [P] Create `examples/default/_header.md` â€” title `# Default example` + description of what the minimal example deploys, features tested list, usage instructions (terraform init/plan/apply)

### full-dual-hub/ Example (Internet + Intranet Hubs)

- [x] T036 [P] Create `examples/full-dual-hub/main.tf` â€” `terraform{}` + `provider{}`, random naming, `module "hub"` with `source = "../../"` â€” dual-hub config: two RGs, hub_internet (firewall + NAT GW + bastion, non-routable 10.0.0.0/16) + hub_intranet (firewall only, routable 10.1.0.0/16), two NSGs, NAT gateway for internet hub, common services VNet (created via `azurerm_virtual_network` within the example â€” examples are self-contained) peered to both hubs, flow logs with wrapper-created storage + traffic analytics, LAW, all in `southeastasia`, `enable_telemetry = false`, zero required input variables
- [x] T037 [P] Create `examples/full-dual-hub/outputs.tf` â€” comprehensive outputs: hub VNet IDs, firewall IPs, NSG IDs, NAT GW IDs, peering IDs, LAW ID, storage account IDs
- [x] T038 [P] Create `examples/full-dual-hub/_header.md` â€” title `# Full Dual-Hub example` + description of internet/intranet topology, features tested list, reference architecture diagram, usage instructions

**Checkpoint**: Both examples created â€” self-contained, zero-input, deployable.

---

## Phase 9: Documentation (terraform-docs)

**Purpose**: Set up terraform-docs configuration and generate all README files

- [x] T039 Create `.terraform-docs.yml` at repository root â€” terraform-docs config for the root module README
- [x] T040 [P] Create `_header.md` at repository root â€” pattern title, overview, features, architecture description, usage instructions
- [x] T041 [P] Create `_footer.md` at repository root â€” Microsoft data collection notice boilerplate
- [x] T042 Run `terraform-docs .` to generate `README.md` at repository root (overwrites existing README.md)
- [x] T043 Run `terraform-docs` for each example directory (`examples/default/`, `examples/full-dual-hub/`) â€” examples refactored to tfvars-driven pattern (main.tf â†’ thin module call, variables.tf â†’ passthrough, terraform.tfvars â†’ all config values)

**Checkpoint**: All READMEs auto-generated by terraform-docs. No hand-edited README content for inputs/outputs.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates, passthrough audit, constitution compliance

- [x] T044 Run `terraform fmt -check -recursive` on root + all examples â€” fix any formatting issues
- [x] T045 Run `terraform validate` on root module â€” fix any validation errors
- [x] T046 [P] Passthrough completeness audit: verify every `module` block in `main.tf` has zero hardcoded values that should be passthrough â€” every AVM module parameter must originate from root-level variables (FR-030). Explicitly verify `diagnostic_settings` passthrough for NSG and NAT Gateway modules (FR-009)
- [x] T047 [P] Verify all input variables have explicit type constraints (no `any`), non-empty `description` attributes, AVM-style conventions, and `sensitive = true` where applicable (FR-016, FR-023, SC-009)
- [x] T048 [P] Verify zero `null_resource`, `local-exec`, `remote-exec`, provisioner, or scripting language artifacts in module source tree (FR-020, FR-021, SC-005)
- [x] T049 [P] Verify all outputs have non-empty `description` attributes (FR-015, SC-010)
- [x] T050 Constitution compliance self-assessment: verify all 8 principles are satisfied in the final implementation (plan.md Constitution Check table)
- [x] T051 Run quickstart.md validation: ensure the consumer quickstart flow (create tfvars â†’ terraform init â†’ plan â†’ apply) works against the final module interface

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies â€” can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) completion â€” BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2) â€” MVP
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2) â€” can start after Phase 2, parallel with US1
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2) â€” can start after Phase 2, parallel with US1/US2
- **User Story 4 (Phase 6)**: Depends on Foundational (Phase 2) â€” can start after Phase 2, parallel with others
- **User Story 5 (Phase 7)**: Depends on Foundational (Phase 2) â€” can start after Phase 2, parallel with others
- **Examples (Phase 8)**: Depends on US1 + US2 + US3 completion (needs all module features for full-dual-hub example)
- **Documentation (Phase 9)**: Depends on Examples (Phase 8) + all variable/output definitions finalized
- **Polish (Phase 10)**: Depends on all previous phases

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 â€” no dependencies on other stories
- **US2 (P2)**: Can start after Phase 2 â€” may use US1 outputs but independently testable
- **US3 (P2)**: Can start after Phase 2 â€” uses peering resources from Phase 2, independently testable
- **US4 (P3)**: Can start after Phase 2 â€” tests BYO logic already in locals.tf
- **US5 (P3)**: Can start after Phase 2 â€” tests passthrough of existing variables

### Within Each User Story

- Core module wiring before validation
- Validation before outputs
- Outputs last (depend on module resources existing)

### Parallel Opportunities

- **Phase 1**: T001â€“T003 (evaluation tasks) can run in parallel. T004â€“T005 (version updates) are [P]. T006 depends on T001â€“T003 outcomes.
- **Phase 2**: T010+T011 (NAT GW variable+module) are [P] with T013 (spoke var). T007â€“T009 are sequential (core pattern â†’ variables â†’ locals).
- **Phase 3â€“7**: All user story phases can run in parallel once Phase 2 completes (if staffing allows).
- **Phase 8**: All example file creation tasks are [P] (different directories).
- **Phase 9**: T040+T041 (header/footer) are [P]. T042â€“T043 depend on T039 (config).
- **Phase 10**: T046â€“T049 (verification tasks) are all [P].

---

## Parallel Example: Setup + Foundational

```
Phase 1 (Setup):
  â”Œâ”€ T001 (eval route_table)
  â”œâ”€ T002 (eval private_dns_zone)     â† all 3 in parallel
  â””â”€ T003 (eval private_dns_zone_link)
       â”‚
       â–¼
  â”Œâ”€ T004 (update MI version)
  â”œâ”€ T005 (update SA version)     â† in parallel
  â””â”€ T006 (clean up locals)

Phase 2 (Foundational):
  T007 (core pattern module) â†’ T008 (passthrough vars) â†’ T009 (locals)
       â”‚
       â”œâ”€ T010 + T011 (NAT GW var + module)  â† parallel track
       â”œâ”€ T013 (spoke var)                    â† parallel track
       â”‚
       â–¼
  T012 (NAT GW local) â†’ T014 (peering resources)
```

## Parallel Example: User Stories (after Phase 2)

```
  Phase 2 Complete
       â”‚
       â”œâ”€â”€â”€ Phase 3: US1 (T015â€“T019)  â† MVP priority
       â”œâ”€â”€â”€ Phase 4: US2 (T020â€“T023)  â† can run parallel
       â”œâ”€â”€â”€ Phase 5: US3 (T024â€“T025)  â† can run parallel
       â”œâ”€â”€â”€ Phase 6: US4 (T026â€“T028)  â† can run parallel
       â””â”€â”€â”€ Phase 7: US5 (T029â€“T030)  â† can run parallel
                    â”‚
                    â–¼
              Phase 8: Examples (T031â€“T038)
                    â”‚
                    â–¼
              Phase 9: Documentation (T039â€“T043)
                    â”‚
                    â–¼
              Phase 10: Polish (T044â€“T051)
```

---

## Implementation Strategy

### MVP Scope

**User Story 1 (Phase 3)** is the MVP. After completing Setup (Phase 1), Foundational (Phase 2), and US1 (Phase 3), a consumer can deploy a single-hub with firewall, bastion, NSGs, and LAW.

### Incremental Delivery

1. **Phase 1â€“2**: Setup + Foundation â€” core pattern integrated
2. **Phase 3**: US1 â€” single-hub MVP (deployable)
3. **Phase 4â€“5**: US2 + US3 â€” multi-hub + peering (full topology)
4. **Phase 6â€“7**: US4 + US5 â€” BYO + toggles (enterprise features)
5. **Phase 8â€“9**: Examples + Docs â€” consumer-facing artefacts
6. **Phase 10**: Polish â€” quality gates passed

### Starter Code Evaluation Notes

Per user instruction: "starter code provided can always be removed if AVM pattern `terraform-azurerm-avm-ptn-alz-connectivity-hub-and-spoke-vnet` already supports it." Tasks T001â€“T003 evaluate:
- **Route Table** (`module "route_table"`): Core pattern creates firewall + user-subnet route tables internally. Remove if no additional custom route tables needed beyond core pattern scope.
- **Private DNS Zone** (`module "private_dns_zone"`): Core pattern manages private link DNS zones, auto-registration, VNet links, resolution policies, DNS resolver. Remove if no additional custom DNS zones needed beyond core pattern scope.
- **Private DNS Zone Link** (`module "private_dns_zone_link"`): Core pattern manages its own zone links. Remove if BYO zone links are not needed.

### terraform-docs Notes

Per user instruction: "use `terraform-docs .` to generate README for the root README as well as individual README for examples."
- **Root README**: Requires `_header.md` + `_footer.md` + `.terraform-docs.yml`. Generated by `terraform-docs .`
- **Example READMEs**: Require `_header.md` only (per user: "for examples `_header.md` is enough"). Generated by `terraform-docs` using `examples/.terraform-docs.yml`.
- Example `_header.md` format follows user-provided sample: title + description + features tested list + usage block (terraform init/plan/apply).
