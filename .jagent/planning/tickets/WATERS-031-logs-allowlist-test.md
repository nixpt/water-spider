# WATERS-031 — test the pod-side `logs` allowlist by executing it

| Field | Value |
|-------|-------|
| **ID** | WATERS-031 |
| **Priority** | P1 |
| **Status** | Done (v0.8.1) |
| **Phase** | Quality |
| **Assignee** | ann |
| **Dependencies** | WATERS-028 (merged, v0.8.0) |
| **Estimated effort** | S |

## Problem

The `logs` path allowlist and its `readlink -f` re-check run in the remote script on the pod. Today's tests only
`grep` the script for `readlink -f`; nothing executes the remote check. A regression could silently open
arbitrary reads. Raised as a nit in usagi's #14 review (head f9baffb).

## Success criteria

- [ ] The remote script's `logs` section runs for real in the docker rehearsal (`WS_TEST_DOCKER=1`,
      `--cap-drop ALL --network none --read-only`) and, where possible, under plain bash in `tests/run.sh`.
- [ ] Cases, each asserting allowed or refused: a file under each allowed root; `/etc/shadow`; `..` traversal;
      `//` and `/./` forms; a symlink under `/workspace` pointing at `/etc/passwd`; a denied credential name.
- [ ] Removing the allowlist check makes the suite fail (a mutation check, noted in the PR).
- [ ] WATERS-029/030 add their cases to this harness.
