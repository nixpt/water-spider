# WATERS-008 — Refresh vendored Dejavue fallback

| Field | Value |
|-------|-------|
| **ID** | WATERS-008 |
| **Priority** | P2 |
| **Status** | Done |
| **Phase** | Project metadata |
| **Assignee** | codex |
| **Dependencies** | WATERS-006 |
| **Estimated effort** | S |

## Problem

Verify that water-spider carries the latest canonical `dejavue.py` fallback and
determine whether its two in-repo Dejavue skills are redundant.

## Reproduction

1. Fetch `/workspace/projects/dejavue` from `origin/master`.
2. Compare versions and SHA-256 hashes for the canonical CLI and both skills.
3. Diff `.dejavue/dejavue/SKILL.md` and
   `.dejavue/dejavue-workflow/SKILL.md`.

## Success criteria

- [x] `.dejavue/dejavue.py` exists, is executable, and matches canonical
  Dejavue 2.1.0.
- [x] Both fallback skills match the canonical Dejavue checkout.
- [x] The roles of the index skill and workflow skill are documented in the
  resolution.
- [x] Existing project memory is preserved.

## Technical approach

- Fast-forward the canonical Dejavue checkout.
- Run its `init --force` command in the ticket worktree to refresh the vendored
  script, skills, and managed hooks.
- Reject duplicate `.gitattributes` entries produced by the legacy marker gap.

## Files modified

- `.dejavue/dejavue-workflow/SKILL.md` — refresh from canonical source.
- `.dejavue/timeline.jsonl` — initializer event.
- `.jagent/planning/` — ticket and task tracking.

## Non-goals

- Collapsing two skills with intentionally different roles.
- Rewriting or deleting project decisions, state, or timeline history.

## Resolution

Canonical `/workspace/projects/dejavue` was already current at commit `7944d45`
and Dejavue 2.1.0. The vendored executable existed and its SHA-256 already
matched; the `dejavue` index skill also matched. The longer workflow skill was
stale and is now refreshed. They are not duplicates: `dejavue` is a concise
command-surface index that routes agents onward, while `dejavue-workflow` is the
full session lifecycle, capture, recall, repository-state, and DCP protocol.
