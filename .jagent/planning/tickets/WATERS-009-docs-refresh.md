# WATERS-009 — Reconcile project documentation

| Field | Value |
|-------|-------|
| **ID** | WATERS-009 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | Planning hygiene |
| **Assignee** | codex |
| **Dependencies** | WATERS-006, WATERS-007, WATERS-008 |
| **Estimated effort** | M |

## Problem

Project docs are individually useful but fragmented and contain stale claims
about remote configuration, live-validation coverage, branch state, runtime
dependencies, and even a Rust-specific issue-template field.

## Success criteria

- [x] `docs/` provides architecture, operations, testing, release, and navigation guides.
- [x] Root, Dejavue, and Jagent state agree on live evidence and remaining work.
- [x] WATERS-003 and WATERS-005 reflect partial completion accurately.
- [x] Generated agent adapters are refreshed from canonical Dejavue context.
- [x] Documentation links, tests, syntax, ShellCheck, and whitespace checks pass.

## Resolution

Added a navigable documentation set, reconciled runtime/release/validation
claims, corrected planning and issue templates, refreshed persistent context and
generated adapters, and verified the resulting repository before push.
