# WATERS-013 — Make release tests follow the current project version

| Field | Value |
|-------|-------|
| **ID** | WATERS-013 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | Release readiness |
| **Assignee** | codex |
| **Dependencies** | WATERS-005 |
| **Estimated effort** | XS |

## Problem

The release bootstrap test hard-codes `v0.1.0`. Once automation updates
`VERSION`, the fixture copies that newer value while creating the old tag, so
every later CI run fails despite valid release behavior.

## Success criteria

- [x] The fixture tags the version copied from `VERSION`.
- [x] Patch-bump expectations are calculated from that version.
- [x] Release and deterministic command tests pass after a real version bump.

## Resolution

The release test now derives its current and next versions from the project's
`VERSION` file instead of embedding bootstrap-era values.
