# Full Spec Review Checklist: PLZ Connectivity Hub VNet Terraform Pattern

**Purpose**: Broad requirements quality review across all dimensions — completeness, clarity, consistency, coverage, and measurability. Includes plan-phase dual-hub refinements to surface gaps between spec and evolved design intent.
**Created**: 2026-03-30
**Feature**: [spec.md](../spec.md)
**Depth**: Standard
**Audience**: Spec author (self-review before sharing)
**Focus**: All dimensions — completeness, clarity, consistency, coverage, measurability

---

## Requirement Completeness

- [x] CHK001 - Is the dual-hub internet/intranet topology (internet egress/ingress hub + intranet ingress hub + common services VNet) documented as a supported topology in the spec? **RESOLVED** — FR-002 updated to enumerate supported topologies including same-region dual-hub. User Story 2 updated with dual-hub acceptance scenario.
- [x] CHK002 - Are requirements defined for the Common Services VNet with DNS Resolver subnet that peers to both hubs? **RESOLVED** — Added FR-032 requiring support for multiple spoke peering entries referencing the same spoke VNet with different hub_keys. User Story 2 acceptance scenario 3 covers this.
- [x] CHK003 - Is an FR defined for the managed identity module (`avm-res-managedidentity-userassignedidentity`) and its use case within the pattern? **RESOLVED** — Added FR-035 and added module to §Architecture justification table.
- [x] CHK004 - Is an FR defined for the role assignment module (`avm-res-authorization-roleassignment`) and when/why RBAC assignments are created? **RESOLVED** — Added FR-036 and added module to §Architecture justification table.
- [x] CHK005 - Are requirements specified for what the `default/` example must demonstrate versus what the `full-dual-hub/` example must demonstrate? **RESOLVED** — Added FR-037 requiring AVM-compliant examples with self-contained, zero-input, deployable convention. Example scope is defined in plan.md example contracts (appropriate level for that detail).
- [x] CHK006 - Are requirements defined for AVM example conventions (self-contained, zero-input, deployable, terraform-docs READMEs, `_header.md`, `_footer.md`)? **RESOLVED** — FR-037 covers all AVM example conventions.
- [x] CHK007 - Is the `random` provider dependency (used for unique naming in examples) documented in spec requirements? **RESOLVED** — FR-017 updated to include `random ~> 3.0`.
- [x] CHK008 - Are requirements defined for the shared terraform-docs config (`examples/.terraform-docs.yml`) and boilerplate example files? **RESOLVED** — FR-037 and FR-019 together cover this (terraform-docs config is an implementation detail of the FR-019/FR-037 requirements).
- [x] CHK009 - Is there an FR for the passthrough principle — that every AVM module parameter MUST be exposed via root-level variables with no hardcoded values in module blocks? **RESOLVED** — Added FR-030.
- [x] CHK010 - Are requirements defined for which subnets can and cannot have NSGs (e.g., AzureFirewallSubnet, GatewaySubnet, AzureBastionSubnet cannot have user-defined NSGs)? **RESOLVED** — FR-003 updated with note about Azure-managed subnet types.
- [x] CHK011 - Is traffic analytics specified as mandatory or optional within the flow log configuration? **RESOLVED** — Added FR-033 specifying traffic analytics as optional, disabled by default, with configurable interval.
- [x] CHK012 - Are requirements defined for the `hub_and_spoke_networks_settings` variable (DDoS plan association, shared settings across hubs)? **RESOLVED** — Added FR-031 requiring exposure of `hub_and_spoke_networks_settings` including mesh peering control.
- [x] CHK013 - Is there an FR requiring the pattern to expose the core pattern's `mesh_peering_enabled` setting for automatic hub-to-hub peering? **RESOLVED** — FR-031 explicitly includes mesh peering control.

## Requirement Clarity

- [x] CHK014 - Is the term "multi-hub topologies" in FR-002 defined with specific supported configurations (same-region dual-hub, multi-region, hub-mesh)? **RESOLVED** — FR-002 now enumerates three supported topologies: multi-region, same-region dual-hub, and single-hub.
- [x] CHK015 - Is "secure-by-default" quantified with specific default values for each resource type (e.g., `public_network_access_enabled = false`, `default_outbound_access_enabled = false`, minimum TLS version)? **RESOLVED** — §Security updated with specific defaults: `public_network_access_enabled = false` for storage, `default_outbound_access_enabled = false` for subnets, `min_tls_version = "TLS1_2"`. SC-009 also updated.
- [x] CHK016 - Is the wildcard exception process defined — "FORBIDDEN unless explicitly justified" — who approves, where is justification documented? **RESOLVED** — Updated §Security to specify justification must be in a PR review and documented in the NSG rule's description attribute.
- [x] CHK017 - Is `default_outbound_access_enabled = false` a MUST or SHOULD requirement? The spec uses "SHOULD" which is weaker than other security requirements that use "MUST". **RESOLVED** — Changed from SHOULD to MUST.
- [x] CHK018 - Is the mechanism for plan-time key validation specified (Terraform validation blocks, preconditions, or provider errors)? **RESOLVED** — FR-024 updated to specify `precondition` or `validation` blocks.
- [x] CHK019 - Is "every supplementary resource that supports them" enumerated — which specific supplementary resources require diagnostic settings? **RESOLVED** — FR-009 updated to enumerate NSGs, NAT Gateways, and User-Assigned Managed Identities.
- [x] CHK020 - Is "AVM-style conventions" for variable descriptions defined with specific formatting rules or a reference to an external style guide? **RESOLVED** — §Documentation updated with link to AVM Terraform contribution guide.
- [x] CHK021 - Are the address space conventions "GEN Non Routable" and "GEN Routable" defined or referenced in the spec? **RESOLVED — N/A** — These are enterprise-specific naming conventions from the consumer's architecture diagram, used only in plan.md example contracts. The spec correctly remains generic; address space planning is the consumer's responsibility.
- [x] CHK022 - Is the BYO conflict resolution rule (both BYO ID and creation config provided simultaneously) elevated to an FR, or only covered in edge cases? **RESOLVED** — Added FR-034 with explicit precedence rule and SHOULD-level validation recommendation.

## Requirement Consistency

- [x] CHK023 - Does FR-017 align with the actual codebase? Spec says `~> 1.12` but `terraform.tf` uses `>= 1.13, < 2.0`. **RESOLVED** — FR-017 updated to `>= 1.13, < 2.0` matching the codebase and plan.md.
- [x] CHK024 - Does FR-017's `azapi ~> 2.4` align with the actual codebase? `terraform.tf` and plan.md both use `azapi ~> 2.0`. **RESOLVED** — FR-017 updated to `azapi ~> 2.0`.
- [x] CHK025 - Do User Story 2's example hub keys (`hub-eus` and `hub-weu`, multi-region) align with the plan-phase topology (`hub_internet` and `hub_intranet`, same-region dual-hub)? **RESOLVED** — User Story 2 rewritten to use `hub_internet` and `hub_intranet` examples and cover both multi-region and same-region dual-hub topologies.
- [x] CHK026 - Is the route table module's role consistent between §Architecture and §In-Scope? Architecture says "core pattern creates route tables internally" but the supplementary module `avm-res-network-routetable` is present in the codebase. **RESOLVED** — §In-Scope updated with clarifying row: additional custom route tables beyond core pattern's are supplementary and flagged for review.
- [x] CHK027 - Is the private DNS zone link module's presence consistent with the architecture statement that "core pattern manages private DNS zones... virtual network links"? **RESOLVED** — §In-Scope updated: supplementary DNS zone links are for BYO zones not managed by core pattern. Core pattern handles its own zone links.
- [x] CHK028 - Does the clarification "wrapper creates a storage account... with BYO fallback" align precisely with FR-026's "provision... OR accept a BYO resource ID"? **RESOLVED** — FR-034 now explicitly defines BYO precedence: BYO ID takes priority over creation config. FR-026 and clarifications are aligned because "OR" means exactly one path, and FR-034 resolves the conflict scenario.
- [x] CHK029 - Are the Assumptions section's provider version references (`azurerm ~> 4.0`, `azapi ~> 2.4`) consistent with FR-017's stated versions? **RESOLVED** — Assumptions updated to `azapi ~> 2.0`, matching FR-017.

## Acceptance Criteria Quality

- [x] CHK030 - Is SC-002 ("independently addressable in outputs") measurable — which specific output keys must be present per hub? **RESOLVED** — SC-002 updated to list specific hub-keyed outputs: `hub_virtual_network_ids`, `hub_virtual_network_names`, `firewall_private_ip_addresses`, `firewall_resource_names`, `bastion_host_dns_names`.
- [x] CHK031 - Is SC-006 ("documented justification") verifiable — where must justifications be located and in what format? **RESOLVED** — SC-006 updated to specify justifications must be in §Architecture's supplementary module table.
- [x] CHK032 - Is SC-009 ("secure-by-default values") measurable — what constitutes "secure-by-default" for each variable type? **RESOLVED** — SC-009 updated with specific values: `public_network_access_enabled = false`, `default_outbound_access_enabled = false`, `min_tls_version = "TLS1_2"`.
- [x] CHK033 - Are acceptance scenarios defined for the dual-hub topology (internet + intranet hubs with distinct capabilities)? **RESOLVED** — User Story 2 acceptance scenario 1 rewritten with `hub_internet` and `hub_intranet` dual-hub example.
- [x] CHK034 - Is there an acceptance scenario for Common Services VNet peering to both hubs (the plan-phase reference architecture)? **RESOLVED** — User Story 2 acceptance scenario 3 added covering dual-hub peering to same common services VNet.

## Scenario Coverage

- [x] CHK035 - Are requirements defined for partial deployment failure (e.g., hub 1 succeeds, hub 2 fails) — expected behavior and recovery? **RESOLVED** — Added to §Edge Cases: pattern relies on Terraform's standard partial-apply behaviour; no custom rollback.
- [x] CHK036 - Are requirements defined for state migration when adding or removing a hub entry from the `hub_virtual_networks` map after initial deployment? **RESOLVED** — Added to §Edge Cases: adding creates new, removing destroys, renaming requires `moved` blocks.
- [x] CHK037 - Are requirements defined for importing existing infrastructure into the pattern's state (`terraform import` or `import` blocks)? **RESOLVED — N/A** — Import is a standard Terraform operation not specific to this pattern's requirements. Not adding an FR — this is a consumer-side operational concern.
- [x] CHK038 - Are requirements defined for the lifecycle of peering resources when a spoke VNet is deleted externally (outside Terraform)? **RESOLVED** — Added to §Edge Cases: drift detection on next plan, Terraform handles recreation/removal.
- [x] CHK039 - Is there a scenario for enabling or disabling flow logs after the initial deployment (e.g., adding flow log config to an existing hub)? **RESOLVED** — Added to §Edge Cases: incremental flow log addition is supported.
- [x] CHK040 - Are requirements specified for concurrent deployment limits or parallelism constraints the core pattern may impose? **RESOLVED** — Added to §Assumptions: no pattern-level constraints; consumer controls via `-parallelism`.
- [x] CHK041 - Is there a user story or scenario covering BYO storage account for flow logs (analogous to User Story 4 for BYO LAW)? **RESOLVED** — User Story 4 acceptance scenario 2 added for BYO storage account.
- [x] CHK042 - Are requirements defined for what happens when a hub's `enabled_resources` flags are changed after initial deployment (e.g., adding bastion to an existing hub)? **RESOLVED — Already covered** — User Story 5 acceptance scenario 2 covers enabling a component after initial deployment. The core pattern handles this internally; the wrapper's responsibility is purely passthrough (FR-010, FR-030).

## Edge Case Coverage

- [x] CHK043 - Are requirements defined for the scenario where both hubs reference the same NSG key (cross-hub NSG sharing)? **RESOLVED** — Added to §Edge Cases: explicitly supported; NSG created once, both hubs reference same ID. Region alignment required.
- [x] CHK044 - Are requirements defined for a NAT Gateway key referenced from a hub subnet that is in a different region than the NAT Gateway resource? **RESOLVED** — Added to §Edge Cases: Azure requires same-region; provider raises error at apply time. Consumer responsibility.
- [x] CHK045 - Is the behavior specified when the `resource_groups` map contains entries not referenced by any hub or supplementary resource (orphaned RGs)? **RESOLVED** — Added to §Edge Cases: orphaned RGs are permitted; all defined RGs are created regardless of references.
- [x] CHK046 - Are requirements specified for overlapping or conflicting address spaces between hubs in the same deployment? **RESOLVED** — Added to §Edge Cases: pattern does not validate address space uniqueness; overlaps cause Azure-level peering failures; consumer responsibility.
- [x] CHK047 - Is the behavior defined when a consumer removes a spoke peering entry but the spoke-side peering resource was already deleted externally? **RESOLVED** — Covered by CHK038 resolution (external spoke deletion edge case). Terraform detects drift and handles reconciliation.

## Non-Functional Requirements Coverage

- [x] CHK048 - Are performance or timeout requirements defined for large deployments (e.g., 10+ NSGs, multiple hubs, dozens of DNS zones)? **RESOLVED** — Added to §Assumptions: no hard limits; practical limits documented; large deployments should split invocations.
- [x] CHK049 - Are requirements defined for the maximum number of supported hubs, NSGs, NAT Gateways, or spoke peerings in a single deployment? **RESOLVED** — Added to §Assumptions: no pattern-imposed limits; governed by Azure quotas, state performance, and API rate limits.
- [x] CHK050 - Are Terraform state size or performance implications documented for large-scale deployments? **RESOLVED** — Added to §Assumptions: guidance for consumers with 10+ hubs/50+ NSGs to split across invocations.
- [x] CHK051 - Are requirements defined for provider authentication scope — single subscription vs multi-subscription (hub and spoke in different subscriptions)? **RESOLVED** — Added to §Assumptions: multi-subscription via provider aliasing; RBAC requirements enumerated.

## Dependencies & Assumptions

- [x] CHK052 - Is the assumption about `terraform-docs` availability elevated to a documented prerequisite with version requirements? **RESOLVED** — §Assumptions updated: `terraform-docs >= 0.18.0`.
- [x] CHK053 - Is the assumption that Network Watcher is "auto-provisioned by Azure or managed by the supplementary module" validated — what if auto-provisioning is disabled on the subscription? **RESOLVED** — §Assumptions updated: supplementary module handles creation; pattern does not assume pre-existence.
- [x] CHK054 - Are RBAC prerequisites for the deploying identity enumerated per resource type (not just "Network Contributor or equivalent")? **RESOLVED** — §Assumptions updated with specific RBAC requirements: Network Contributor for peering, Contributor for RG operations, User Access Administrator for role assignments.
- [x] CHK055 - Is the dependency on the core AVM pattern module's specific features (mesh peering, feature flags, naming conventions) version-locked to v0.16.14's capabilities? **RESOLVED** — §Assumptions updated: pattern targets v0.16.14 specifically; feature availability locked to this version.

## Ambiguities & Conflicts

- [x] CHK056 - Is the discrepancy between the spec's FR-017 Terraform version (`~> 1.12`) and the codebase's version (`>= 1.13, < 2.0`) explicitly resolved with a decision record? **RESOLVED** — FR-017 updated to `>= 1.13, < 2.0`. Assumptions section aligned. research.md R-006 serves as the decision record.
- [x] CHK057 - Is a requirement & acceptance criteria ID scheme established that links FRs → SCs → User Stories → Edge Cases for full traceability? **RESOLVED** — Added §Traceability subsection under Success Criteria with FR→SC mapping.
- [x] CHK058 - Are the supplementary modules in §Architecture's justification table complete? Managed identity and role assignment modules are present in codebase but absent from the table. **RESOLVED** — Added managed identity and role assignment modules to §Architecture justification table with justification text.

---

## Notes

- All 58 items resolved. 52 items required spec changes; 6 items were resolved as N/A or already covered.
- Net new FRs added: FR-030 through FR-037 (8 new requirements).
- Key version fixes: FR-017 updated from `~> 1.12` / `azapi ~> 2.4` to `>= 1.13, < 2.0` / `azapi ~> 2.0` / `random ~> 3.0`.
- §Edge Cases expanded from 4 to 13 entries.
- §Assumptions expanded from 8 to 12 entries with specific versions, RBAC roles, and scale guidance.
- User Story 2 rewritten for dual-hub topology with 3 acceptance scenarios.
- User Story 4 extended with BYO storage account scenario.
- Traceability matrix added linking all FRs to SCs.
