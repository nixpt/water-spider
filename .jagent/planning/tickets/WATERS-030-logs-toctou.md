# WATERS-030 — `logs`: close the readlink-to-tail race

| Field | Value |
|-------|-------|
| **ID** | WATERS-030 |
| **Priority** | P2 |
| **Status** | Open |
| **Phase** | Operations |
| **Assignee** | — |
| **Dependencies** | WATERS-028 (merged, v0.8.0) |
| **Estimated effort** | S |

## Problem

On the pod, `logs` resolves the path with `readlink -f`, checks the allowlist and deny list, then runs `tail` on the
path. Between the check and the `tail`, a path component can be swapped for a symlink to a file outside the allowlist
(time-of-check/time-of-use). Raised as a nit in usagi's #14 review (head f9baffb). Low risk on our own pods, but
the tool is meant for shared or rented ones too.

## Success criteria

- [ ] `tail` reads the exact file that was checked: open it once (e.g. `exec 3<"$resolved"`), verify
      `/proc/self/fd/3` still resolves inside the allowlist and passes the deny list, then `tail` from fd 3
      (`tail -f /proc/self/fd/3` or `tail --pid … -f /dev/fd/3` for `--follow`).
- [ ] No regression in `--follow` cleanup (no orphan `tail` after the client disconnects).
- [ ] A test swaps a symlink between check and read (simulated through the fakes or the docker rehearsal) and the
      read is refused.
