# WATERS-034 — fix CI ShellCheck (SC2015 under the pinned v0.10.0)

| Field | Value |
|-------|-------|
| **ID** | WATERS-034 |
| **Priority** | P1 |
| **Status** | In Review |
| **Phase** | Quality |
| **Assignee** | ann |
| **Dependencies** | WATERS-028 |
| **Estimated effort** | XS |

## Problem

`.github/workflows/ci.yml` runs `ludeeus/action-shellcheck` with ShellCheck v0.10.0. That version reports SC2015
("A && B || C is not if-then-else") at six `[ .. ] && [ .. ] || die ...` lines in `bin/water-spider`. The local
ShellCheck (0.11.0) is silent about them, so "shellcheck clean" held locally while main CI was red from #13 (ddd688b)
onward.

## Success criteria

- [x] The six sites are explicit `if ! { A && B; }; then die ...; fi`, with identical behaviour; no blanket disables.
- [x] ShellCheck v0.10.0 (`-f gcc`) is clean on every shell file in the repo.
- [x] docs/testing.md says local gates must use the CI-pinned ShellCheck version.
- [ ] The PR's GitHub CI test job passes.

## Non-goals

No behaviour change; no bump of the pinned action or version.
