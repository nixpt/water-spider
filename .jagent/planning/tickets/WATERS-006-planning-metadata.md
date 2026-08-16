# WATERS-006 — Replace scaffold placeholders with accurate project metadata

| Field | Value |
|-------|-------|
| **ID** | WATERS-006 |
| **Priority** | P2 |
| **Status** | Backlog |
| **Phase** | Project metadata |
| **Assignee** | unassigned |
| **Dependencies** | none |
| **Estimated effort** | S |

## Problem

Planning files still describe the project as Rust, leave its protocol and north star as TODO, and report that work has not started even though the full Bash implementation is present. This makes agent onboarding and backlog selection unreliable.

## Reproduction

1. Read `.jagent/PROJECT.md` and observe `Language: Rust` and a TODO protocol.
2. Read `.jagent/planning/ROADMAP.md` and observe placeholder north-star, phase, and milestone content.
3. Compare those claims with `STATE.md` and `bin/water-spider`.

## Success criteria

- [ ] Project metadata identifies Bash and the RunPod lifecycle CLI protocol accurately.
- [ ] The roadmap defines a concrete north star and sequences the existing tickets into milestones.
- [ ] Planning state reports the current implementation and validation maturity.
- [ ] Dejavue context contains useful build/test and architecture guidance rather than empty stubs.

## Technical approach

- Reconcile `.jagent` metadata with the root README and state file.
- Turn current ticket dependencies into a small milestone sequence.
- Record durable operating facts in Dejavue through its supported commands.

## Files to modify

- `.jagent/PROJECT.md` — correct language and protocol.
- `.jagent/planning/ROADMAP.md` — replace placeholders.
- `.jagent/planning/STATE.md` — record current maturity.
- `.dejavue/` — update persistent context using Dejavue tooling.

## Non-goals

- Changing CLI behavior.
