# WATERS-007 — Add public repository and contribution conventions

| Field | Value |
|-------|-------|
| **ID** | WATERS-007 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | Release readiness |
| **Assignee** | codex |
| **Dependencies** | WATERS-001, WATERS-002, WATERS-006 |
| **Estimated effort** | M |

## Problem

The public repository lacks explicit license texts, contribution guidance, a
changelog, and an agent instruction adapter. These conventions exist in sibling
project `checkstand` but need adaptation to water-spider's billable-resource
safety model and Bash workflow.

## Reproduction

1. From the repository root, test for `LICENSE-MIT`, `LICENSE-APACHE`,
   `CONTRIBUTING.md`, `CHANGELOG.md`, and `AGENTS.md`.
2. Observe that they are absent before this ticket.

## Success criteria

- [x] Standard MIT and Apache-2.0 license texts name the correct copyright holder.
- [x] Contribution guidance documents setup, tests, ticket/worktree discipline,
  cost safety, secret handling, live verification, and release conventions.
- [x] A changelog distinguishes project versions from the `runpodctl` Docker tag.
- [x] `AGENTS.md` is generated from the canonical Dejavue context.
- [x] The README links contribution and license documentation.

## Technical approach

- Reuse checkstand's dual-license and documentation structure.
- Replace checkstand-specific Rust/adapter rules with water-spider's Bash,
  RunPod, and cost-safety conventions.
- Generate rather than hand-maintain the Codex instruction adapter.

## Files modified

- `LICENSE-MIT`, `LICENSE-APACHE` — standard dual-license texts.
- `CONTRIBUTING.md` — contributor and agent workflow.
- `CHANGELOG.md` — release history surface.
- `AGENTS.md` — generated Dejavue adapter.
- `README.md`, `.gitignore`, `.jagent/planning/` — navigation and tracking.

## Non-goals

- Copying checkstand's Rust-specific architecture or `dev` branch policy.
- Inventing security, support, or conduct policies not present in the source repo.

## Resolution

Adapted checkstand's public-repository conventions to water-spider, retaining its
dual MIT/Apache-2.0 model and generated-agent-document practice while making the
workflow specific to a cost-sensitive Bash/RunPod CLI.
