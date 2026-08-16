# WATERS-010 — Repair release bootstrap and add repository safety rails

| Field | Value |
|-------|-------|
| **ID** | WATERS-010 |
| **Priority** | P0 |
| **Status** | Done |
| **Phase** | Release readiness |
| **Assignee** | codex |
| **Dependencies** | WATERS-001, WATERS-005 |
| **Estimated effort** | M |

## Problem

Release runs succeed without producing versions because the repository has no
initial tag or version surface. CI also fails on ShellCheck findings in the
release script, and GitHub has no protection against deleting or force-pushing
`main`.

## Success criteria

- [x] CI passes with ShellCheck pinned to the locally verified version.
- [x] `VERSION` and `v0.1.0` establish the project release surface.
- [x] A tagged HEAD is a successful no-op; later untagged work selects the next version.
- [x] GitHub has active `fleet-default` protection without breaking release pushes.
- [x] Jokersquad repository tools and the unrelated cece-code path are documented.

## Non-goals

- Applying PR-required protection that rejects the release bot's direct push.
- Vendoring fleet-private repository-management scripts into the public repo.

## Resolution

GitHub logs proved release runs were successful no-ops because no initial tag
existed. Added `VERSION=0.1.0`, an exact-tag bootstrap guard, isolated release
tests, full-script ShellCheck coverage pinned to 0.10.0, and the active
`fleet-default-main-protection` ruleset. Documented `git-ops`, `gh-ruleset`,
audit/sweep tools, and why `text-editor-core` is unrelated.
