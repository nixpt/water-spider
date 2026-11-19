# WATERS-024 — rest.runpod.io is gone: move pod reads and terminate to GraphQL

| Field | Value |
|-------|-------|
| **ID** | WATERS-024 |
| **Priority** | P0 |
| **Status** | In Review |
| **Phase** | Release Readiness |
| **Assignee** | ann |
| **Dependencies** | none |
| **Estimated effort** | M |

## Problem

runpodctl 2.1.9 sends `pod list|get|delete|create` to `rest.runpod.io`, which no longer resolves.
list, status, get, teardown (delete and verify) and the create duplicate guard all failed. The
pre-create listing also swallowed the failure (`|| echo "(none)"`), so a dead listing read as "no pods".

## Success criteria

- [x] list/status/get/teardown-verify and create guards use GraphQL `ws_pods_json`.
- [x] Teardown terminates via `podTerminate` (fakes only) and is "gone" only after a fresh successful listing.
- [x] A failed verify query is UNKNOWN; a failed listing makes create refuse (fail closed).
- [x] Default create is gated on runpodctl >= 3.1.1.
- [x] Fake-backed tests for each of the above; live read-only smoke of status/list/gpus.
- [ ] Live `podTerminate` and live `pod create` on runpodctl >= 3.1.1 (needs a capped pod; captain).

See `docs/RUNPOD-API-2026-11.md`.
