# WATERS-010 — Repair release bootstrap and add repository safety rails

| Field | Value |
|-------|-------|
| **ID** | WATERS-010 |
| **Priority** | P0 |
| **Status** | In Progress |
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

- [ ] CI passes with ShellCheck pinned to the locally verified version.
- [ ] `VERSION` and `v0.1.0` establish the project release surface.
- [ ] A tagged HEAD is a successful no-op; later untagged work selects the next version.
- [ ] GitHub has active `fleet-default` protection without breaking release pushes.
- [ ] Jokersquad repository tools and the unrelated cece-code path are documented.

## Non-goals

- Applying PR-required protection that rejects the release bot's direct push.
- Vendoring fleet-private repository-management scripts into the public repo.
