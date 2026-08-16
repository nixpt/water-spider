# WATERS-003 — Validate unproven workflows against one controlled live pod

| Field | Value |
|-------|-------|
| **ID** | WATERS-003 |
| **Priority** | P0 |
| **Status** | Backlog |
| **Phase** | Operational validation |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-002 |
| **Estimated effort** | M |

## Problem

The source explicitly marks SSH-info parsing, send/receive, tunnels, recipes, GUI forwarding, and snapshots as not live-tested. Interface assumptions in these paths cannot all be established with mocks alone.

## Reproduction

1. Run `rg -n 'NOT live-tested|not live-tested|unverified shape' bin/water-spider README.md`.
2. Confirm the affected workflows have no recorded live validation evidence.

## Success criteria

- [ ] A capped, time-boxed validation plan states the image, GPU, maximum duration, and expected maximum cost before pod creation.
- [ ] Direct SSH parsing, tunnel start/stop, one small send/receive round trip, recipe serving, and snapshot output are exercised and recorded.
- [ ] GUI forwarding is either verified or left explicitly unsupported with the exact blocker documented.
- [ ] The pod is deleted and absence is independently verified at the end of the run.
- [ ] Source caveats and README status are updated to reflect observed behavior.

## Technical approach

- Use one low-cost pod and an idempotency key; capture sanitized command/output evidence.
- Exercise cheapest workflows first and maintain a hard teardown deadline.
- Convert every discovered interface mismatch into its own ticket rather than expanding this validation ticket.

## Files to modify

- `bin/water-spider` — update validation notes only where evidence supports it.
- `README.md` — state the verified compatibility surface.
- `.jagent/planning/` — record findings and any follow-up tickets.

## Non-goals

- Continuous billable integration testing.
- Benchmarking GPU or model performance.
