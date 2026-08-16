# WATERS-001 — Make the CLI ShellCheck-clean

| Field | Value |
|-------|-------|
| **ID** | WATERS-001 |
| **Priority** | P0 |
| **Status** | Done |
| **Phase** | Core health |
| **Assignee** | unassigned |
| **Dependencies** | none |
| **Estimated effort** | S |

## Problem

CI invokes ShellCheck, but the repository does not record a locally verified clean run. The primary artifact is an 803-line strict-mode Bash script, so static-analysis failures can block every push or conceal portability defects.

## Reproduction

1. Install the same ShellCheck version used by CI.
2. Run `shellcheck bin/water-spider` from the repository root.
3. Record all diagnostics and the tool version.

## Success criteria

- [x] `shellcheck bin/water-spider` exits zero without blanket file-level suppression.
- [x] Any targeted suppression documents why the flagged construct is intentional.
- [x] CI uses a pinned ShellCheck action revision or version instead of a mutable branch.

## Technical approach

- Run ShellCheck locally and fix diagnostics without weakening `set -euo pipefail`.
- Add narrow inline directives only where a safe dynamic construct cannot be expressed otherwise.
- Pin the CI action to a stable release or commit.

## Files to modify

- `bin/water-spider` — resolve actionable diagnostics.
- `.github/workflows/ci.yml` — pin the static-analysis toolchain.

## Non-goals

- Rewriting the Bash CLI in another language.

## Resolution

Verified with ShellCheck 0.10.0. The invalid inline directive comment was split from its explanation, four ambiguous `A && B || die` checks were rewritten as explicit conditionals, and CI now pins `ludeeus/action-shellcheck@2.0.0`. `shellcheck bin/water-spider`, `bash -n bin/water-spider`, and the `--help` smoke check all exit zero.
