# WATERS-026 — Route the default `create` through GraphQL

| Field | Value |
|-------|-------|
| **ID** | WATERS-026 |
| **Priority** | P0 |
| **Status** | Backlog |
| **Phase** | Release Readiness |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-024 (merged, 7f54afb) |
| **Estimated effort** | S |

## Problem

WATERS-024 moved pod reads and terminate to GraphQL, but a plain `water-spider create` (no
GraphQL-only flag) still calls `runpodctl pod create`. On runpodctl 2.1.9 that hits the retired
rest.runpod.io, so `ws_create` refuses with "needs runpodctl >= 3.1.1". On 2026-11-19 (bro-cli A6000
pod, ann) the only way to create was to add a no-op `--min-download 1` to force the GraphQL path.
Upgrading runpodctl is not approved on [zorro].

## Success criteria

- [ ] `water-spider create` with no GraphQL-only flags creates via `ws_create_via_graphql`.
- [ ] The idempotency-key replay, id verification and post-create checks work identically on that path.
- [ ] `--cloud SECURE|COMMUNITY`, `--disk`, `--volume 0` (no network volume) and `--ports` map to the GraphQL input.
- [ ] tests/run.sh covers the default create through a fake GraphQL endpoint; no live pod is needed.
- [ ] The runpodctl `pod create` path is kept only behind an explicit opt-in (or removed), and the docs say which.

## Technical approach

- Make GraphQL the default branch in `cmd_create`; drop the "needs runpodctl >= 3.1.1" refusal for the default case.
- Reuse the `ws_create_via_graphql` argument mapping; fill in the defaults the runpodctl path supplied implicitly.
- Keep the "do NOT blindly retry" error text and the idempotency-key lookup before any retry.

## Files to modify

- `bin/water-spider` — `cmd_create`, `ws_create`, `ws_create_via_graphql`
- `tests/` — default-create case against the GraphQL fake
- `docs/operations.md` — create path and the runpodctl version note

## Non-goals

- Upgrading runpodctl.
- New GPU/cloud selection logic.
