# WATERS-028 — pod visibility: `top` + `logs` + `watch --json`

| Field | Value |
|-------|-------|
| **ID** | WATERS-028 |
| **Priority** | P1 |
| **Status** | Open |
| **Phase** | Operations |
| **Assignee** | ann |
| **Dependencies** | WATERS-027 |
| **Estimated effort** | M |

## Scope

- `top <pod>`: one-screen dashboard (GPU, cgroup CPU/RAM, /workspace df, net rx/tx, top procs, live spend when the API is available), refresh N >= 5 s.
- `logs <pod> [<path>|--follow] [--sync]`: read-only tail, one long ssh for --follow, redaction applies.
- `watch <pod> --json [--interval N] [--out FILE]`: one JSON snapshot per tick for guards and a command-center panel.
- Same rules as 027 (one round trip per tick, ControlMaster, read-only, redaction, flags, tests without a pod).
- Later: expose ps/gpu/watch as MCP control-profile tools over ssh (the MCP node profile already has `gpu_status`).
