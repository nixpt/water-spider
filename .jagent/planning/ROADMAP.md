# Roadmap — water-spider

Living plan. Dejavue holds *why*; this file holds *sequence*.

## North star

Ship a standalone, cost-safe RunPod lifecycle CLI that lets a local development
harness provision, connect to, use, and reliably tear down GPU pods without
depending on the internal nixpt fleet layout. Every non-billable behavior is
covered by deterministic tests; operations that depend on RunPod's live data
shapes carry recorded, time-boxed validation evidence.

## Current phase: M1 — Operational validation

The implementation, static analysis, command harness, and GraphQL input
hardening are complete. Live validation and public release remain.

---

## Milestones

- **M0 — Core health** — complete
  - WATERS-001: ShellCheck-clean CLI and pinned static-analysis CI
  - WATERS-002: deterministic command-level harness
  - WATERS-004: safe GraphQL input construction and validation
- **M1 — Operational validation** — pending authorization
  - WATERS-003: one capped, controlled live-pod validation campaign
- **M2 — Public release** — pending repository-owner decisions
  - WATERS-005: establish version surface, canonical remote, tag, and release
- **M3 — Planning hygiene** — complete
  - WATERS-006: accurate project metadata, roadmap, and persistent context

## Non-goals

- Reimplementing RunPod APIs already exposed by `runpodctl`.
- Continuous billable integration tests.
- Treating pod storage as a durable backup or repository of record.
