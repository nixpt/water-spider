# WATERS-036 — `logs`: a FIFO swapped in after the check hangs the open

| Field | Value |
|-------|-------|
| **ID** | WATERS-036 |
| **Priority** | P2 |
| **Status** | Open |
| **Phase** | Operations |
| **Assignee** | ann |
| **Dependencies** | WATERS-030 (merged, v0.8.1) |
| **Estimated effort** | S |

## Problem

From usagi's #16 review (findings 1, 7, 8, head e742c32,
https://github.com/nixpt/water-spider/pull/16#issuecomment-7033295327):

1. **FIFO hang.** The pod script checks `-f` before `exec 3<"$r"`. If the path is swapped for a FIFO (or a device)
   after the check, in a writable directory under /tmp or /workspace, the open blocks until a writer appears. That
   happens before the fd re-check can refuse it. The result is a hung `logs` client, not a read.
2. **Loose mutation assertion.** The `fdcheck` mutation check in `tests/run.sh` matches the text "changed after the
   check", which also appears in the always-printed case name. The real signal is rc 1 / "not ok".
3. **Untested window.** The race test swaps the target during the check's `readlink` (a PATH shim). Nothing swaps
   between the open and the fd re-check.

## Success criteria

- [ ] The open cannot block forever. Two candidates; pick one and justify it in the PR:
  - open with `O_NONBLOCK` (FIFOs open at once without a writer), then refuse anything that is not a regular file
    by checking `/proc/self/fd/3`. Bash has no non-blocking open, so this needs a helper the pod is known to have;
    say which, and what happens when it is missing;
  - or bound the open with `timeout`, ending with a clear "refused: not a regular file, or the open timed out".
  Do not re-open by path (for example through a process substitution); that would bring back the WATERS-030 race.
  After the open, the fd check still refuses a FIFO or a device.
- [ ] A test swaps the path for a FIFO between the check and the open. `logs` ends within a few seconds with the
      refusal, and no `tail` or `bash` is left behind.
- [ ] The `fdcheck` mutation assertion matches "not ok" for the race case (or rc), not the case-name text.
- [ ] A test swaps the target between the open and the fd re-check (a shim on the re-check step) and the read is
      refused, or the PR explains why that window cannot be driven from the harness.
- [ ] `--follow` cleanup still leaves no orphan `tail` (the existing exec test passes).

## Notes

Impact is a denial of your own session, not a leak, so P2. Read-only tool; tests use local bash or `--network none`
docker, never a pod.
