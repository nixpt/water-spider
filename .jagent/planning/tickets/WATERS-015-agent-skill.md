# WATERS-015 — Add a cost-safe water-spider skill for agents

| Field | Value |
|-------|-------|
| **ID** | WATERS-015 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | Agent integration |
| **Assignee** | codex |
| **Dependencies** | WATERS-014 |
| **Estimated effort** | S |

## Problem

The CLI and user guides describe safe operation, but an agent invoking the tool
has no discoverable procedural package that distinguishes inspection from
billable or destructive actions and preserves the live-evidence boundary.

## Success criteria

- [x] A valid `water-spider` skill is packaged under `.jagent/skills/`.
- [x] Trigger metadata covers operation, diagnosis, Docker images, and project work.
- [x] The skill requires explicit cost/runtime and teardown boundaries before creation.
- [x] It forbids blind retries and requires independent teardown verification.
- [x] It routes agents to maintained repository guides instead of duplicating them.
- [x] Agent UI metadata is present and the package passes skill validation.

## Resolution

Added `.jagent/skills/water-spider` with concise task classification, live
operation guardrails, recovery rules, evidence reporting, project verification,
and progressive links to the maintained documentation set.
