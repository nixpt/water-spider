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

## P1 — Release Readiness

- [x] [WATERS-018](tickets/WATERS-018-ghcr-publishing.md) — Publish all image variants to GHCR on release
- [x] [WATERS-016](tickets/WATERS-016-mcp-readonly.md) — Add read-only control and node MCP profiles
- [ ] [WATERS-017](tickets/WATERS-017-mcp-billable-leases.md) — Add enforceable MCP leases before billable lifecycle tools
- [x] [WATERS-013](tickets/WATERS-013-release-test-current-version.md) — Make release tests follow the current project version
- [x] [WATERS-005](tickets/WATERS-005-release-bootstrap.md) — Bootstrap versioning, remote, and initial release
- [x] [WATERS-007](tickets/WATERS-007-community-docs.md) — Add public repository and contribution conventions
- [x] [WATERS-009](tickets/WATERS-009-docs-refresh.md) — Reconcile project documentation and navigation

## P2 — Project Metadata

- [x] [WATERS-019](tickets/WATERS-019-v2-operator-guide.md) — Document v2 GPU, llama.cpp, GUI, storage, and MCP use
- [x] [WATERS-015](tickets/WATERS-015-agent-skill.md) — Add a cost-safe water-spider skill for agents
- [x] [WATERS-014](tickets/WATERS-014-user-guides.md) — Restructure the README and add user-facing guides
- [x] [WATERS-012](tickets/WATERS-012-dockerhub-documentation.md) — Publish maintained Docker Hub documentation
- [x] [WATERS-011](tickets/WATERS-011-brand-assets.md) — Create the project logo and repository asset kit
- [x] [WATERS-006](tickets/WATERS-006-planning-metadata.md) — Replace scaffold placeholders with accurate project metadata
- [x] [WATERS-008](tickets/WATERS-008-dejavue-refresh.md) — Refresh vendored Dejavue fallback and audit skills
