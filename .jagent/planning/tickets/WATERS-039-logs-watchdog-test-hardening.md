# WATERS-039 — logs: harden the watchdog tests (#19 review follow-ups)

| Field | Value |
|-------|-------|
| **ID** | WATERS-039 |
| **Priority** | P2 |
| **Status** | Open |
| **Phase** | Quality |
| **Assignee** | ann |
| **Dependencies** | WATERS-035, WATERS-036 (#19) |
| **Estimated effort** | S |

## Problem

usagi's review of #19 (head 159ba14, https://github.com/nixpt/water-spider/pull/19#issuecomment-7039209807) approved
it with one should-fix and several nits:

- If the open watchdog regresses, the FIFO case in `tests/logs-exec.sh` (~157-160) hangs the suite instead of
  failing it. With the watchdog line deleted, the suite ran until `timeout 60` killed it (rc 124). CI sets no
  `timeout-minutes`, so a regression would block until GitHub's 6 h limit. No mutation covers the watchdog.
- `WS_LOGS_OPEN_TIMEOUT` is read from the pod environment; `inf` (or any non-positive-integer) makes the open
  unbounded again. The client does not send it, so it is pod-side only.
- `*/.kube/*` appears twice in `ws_logs_guard_src`.
- Some new deny cases are already refused by older patterns, so they do not prove the new pattern; `faillog` has no
  case; `.ssh2_dummy` is an unused fixture.
- Near-misses outside 035's list still pass: `*.tfvars.json`, `.terraformrc`, `known_hosts.old`,
  `/var/log/audit/audit.log`, `/var/log/journal/**`, `/var/log/sudo.log`.

## Success criteria

- [ ] The FIFO case is bounded (e.g. `timeout 20`), so a broken watchdog fails the case, not hangs the suite.
- [ ] `LOGS_MUTATE=watchdog` exists, and `tests/run.sh` asserts it fails (by "not ok"/rc).
- [ ] The CI test job has a `timeout-minutes`.
- [ ] `WS_LOGS_OPEN_TIMEOUT` is validated as a small positive integer (clamped or rejected, default 5); test it.
- [ ] The duplicate `*/.kube/*` is removed; every new deny name has a case that only the new pattern refuses
      (`faillog` included); the unused fixture is removed.
- [ ] Decide each near-miss above: deny it with a test, or note in docs/operations.md why it is allowed.
- [ ] Mutations allowlist/deny/fdcheck/watchdog all fail; shellcheck 0.10.0 clean.
