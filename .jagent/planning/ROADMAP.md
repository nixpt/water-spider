# Roadmap — water-spider

Living plan. Dejavue holds *why*; this file holds *sequence*.

## North star

Ship a standalone, cost-safe RunPod lifecycle CLI that lets a local development
harness provision, connect to, use, and reliably tear down GPU pods without
depending on the internal nixpt fleet layout. Every non-billable behavior is
covered by deterministic tests; operations that depend on RunPod's live data
shapes carry recorded, time-boxed validation evidence.

## Current phase: M1 — Operational validation

The implementation, static analysis, command harness, GraphQL hardening,
published images, and core create/tunnel/inference/teardown live path are
complete. Four peripheral live workflows and the first project-version tag
remain.

---

## Milestones

- **M0 — Core health** — complete
  - WATERS-001: ShellCheck-clean CLI and pinned static-analysis CI
  - WATERS-002: deterministic command-level harness
  - WATERS-004: safe GraphQL input construction and validation
- **M1 — Operational validation** — core path proven; peripheral paths pending
  - WATERS-003: validate transfer, recipe wrapper, GUI, and snapshot workflows
- **M2 — Public release** — complete
  - WATERS-005: version surface, initial tag, ruleset, and bump proof
  - WATERS-010: CI/release bootstrap repair and repository safety tooling
- **M3 — Planning hygiene** — complete
  - WATERS-006: accurate project metadata, roadmap, and persistent context
  - WATERS-007: public contribution, license, and changelog conventions
  - WATERS-008: canonical Dejavue fallback and skills
  - WATERS-009: complete documentation reconciliation and navigation
- **M4 — MCP agent surface** — foundation complete
  - WATERS-016: read-only control/node profiles, stdio, and tunneled HTTP
  - WATERS-017: enforceable leases before create/teardown tools

## Non-goals

- Reimplementing RunPod APIs already exposed by `runpodctl`.
- Continuous billable integration tests.
- Treating pod storage as a durable backup or repository of record.
