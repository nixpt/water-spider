# WATERS-017 — Add enforceable MCP leases before billable lifecycle tools

| Field | Value |
|-------|-------|
| **ID** | WATERS-017 |
| **Priority** | P0 |
| **Status** | Ready |
| **Phase** | MCP lifecycle |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-016 |
| **Estimated effort** | L |

## Problem

An MCP create tool makes agent retries and unattended billing easier. Requiring
budget fields in a schema is not enforcement: the server can exit, the host can
sleep, and a requested deadline can pass without deleting the pod.

## Success criteria

- [ ] `pod_create` requires a stable idempotency key, maximum hourly price,
      maximum runtime, and absolute teardown deadline.
- [ ] A preflight plan resolves the intended template/image/GPU and rejects
      selections above the stated price bound before creation.
- [ ] A durable lease survives MCP client disconnects and server restarts.
- [ ] Deadline enforcement has a separately supervised execution path and
      reports when host availability prevents a hard guarantee.
- [ ] `pod_teardown` preserves declared artifacts and independently proves absence.
- [ ] Tool annotations and server-side policy correctly distinguish planning,
      additive creation, and destructive teardown.
- [ ] Duplicate, concurrent, timeout, restart, and failed-delete cases have
      deterministic tests before any authorized live campaign.

## Non-goals

- Claiming a hard financial cap when enforcement still depends on one laptop
  remaining online.
- Generic remote shell access.
