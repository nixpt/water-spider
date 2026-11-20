# TASKS — water-spider

Every open item below represents a planned task or issue. See `.jagent/planning/tickets/` for
full details on each `WATERS-N` ID.

---

## P0 — Build & Core Health

- [x] [WATERS-010](tickets/WATERS-010-release-gitops.md) — Repair release bootstrap and add repository safety rails
- [x] [WATERS-001](tickets/WATERS-001-shellcheck-clean.md) — Make `shellcheck bin/water-spider` clean
- [x] [WATERS-002](tickets/WATERS-002-command-test-harness.md) — Add a mocked command-level test harness
- [ ] [WATERS-003](tickets/WATERS-003-live-runpod-validation.md) — Validate unproven workflows against one controlled live pod
- [x] [WATERS-004](tickets/WATERS-004-graphql-path-hardening.md) — Harden GraphQL dependencies and input construction

## P0 — Live breakage

- [x] [WATERS-028](tickets/WATERS-028-pod-top-logs-watch.md) — Pod visibility: top + logs + watch --json
- [x] [WATERS-027](tickets/WATERS-027-pod-ps-gpu.md) — Pod visibility: ps + gpu (read-only, one ssh round trip)
- [ ] [WATERS-024](tickets/WATERS-024-runpod-rest-host-gone.md) — rest.runpod.io is gone: move pod reads and terminate to GraphQL

## P1 — Release Readiness

- [ ] [WATERS-031](tickets/WATERS-031-logs-allowlist-test.md) — Test the pod-side logs allowlist by executing it
- [ ] [WATERS-029](tickets/WATERS-029-logs-deny-patterns.md) — logs: widen the credential deny patterns
- [ ] [WATERS-022](tickets/WATERS-022-wsforge-pod-confinement.md) — Bake wsforge-style agent confinement into the pod images
- [ ] [WATERS-021](tickets/WATERS-021-ampere-agent-validation.md) — Publish and live-validate Ampere agent inference
- [x] [WATERS-020](tickets/WATERS-020-mayfly-opencode.md) — Connect Mayfly and OpenCode to tunneled v2 inference
- [x] [WATERS-018](tickets/WATERS-018-ghcr-publishing.md) — Publish all image variants to GHCR on release
- [x] [WATERS-016](tickets/WATERS-016-mcp-readonly.md) — Add read-only control and node MCP profiles
- [ ] [WATERS-017](tickets/WATERS-017-mcp-billable-leases.md) — Add enforceable MCP leases before billable lifecycle tools
- [x] [WATERS-013](tickets/WATERS-013-release-test-current-version.md) — Make release tests follow the current project version
- [x] [WATERS-005](tickets/WATERS-005-release-bootstrap.md) — Bootstrap versioning, remote, and initial release
- [x] [WATERS-007](tickets/WATERS-007-community-docs.md) — Add public repository and contribution conventions
- [x] [WATERS-009](tickets/WATERS-009-docs-refresh.md) — Reconcile project documentation and navigation

## P2 — Project Metadata

- [ ] [WATERS-032](tickets/WATERS-032-help-visibility-commands.md) — --help lists top, logs and watch
- [ ] [WATERS-030](tickets/WATERS-030-logs-toctou.md) — logs: close the readlink-to-tail race
- [x] [WATERS-019](tickets/WATERS-019-v2-operator-guide.md) — Document v2 GPU, llama.cpp, GUI, storage, and MCP use
- [x] [WATERS-015](tickets/WATERS-015-agent-skill.md) — Add a cost-safe water-spider skill for agents
- [x] [WATERS-014](tickets/WATERS-014-user-guides.md) — Restructure the README and add user-facing guides
- [x] [WATERS-012](tickets/WATERS-012-dockerhub-documentation.md) — Publish maintained Docker Hub documentation
- [x] [WATERS-011](tickets/WATERS-011-brand-assets.md) — Create the project logo and repository asset kit
- [x] [WATERS-006](tickets/WATERS-006-planning-metadata.md) — Replace scaffold placeholders with accurate project metadata
- [x] [WATERS-008](tickets/WATERS-008-dejavue-refresh.md) — Refresh vendored Dejavue fallback and audit skills
