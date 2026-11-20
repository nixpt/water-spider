# WATERS-027 — pod visibility: `ps` + `gpu` (read-only, one ssh round trip)

| Field | Value |
|-------|-------|
| **ID** | WATERS-027 |
| **Priority** | P1 |
| **Status** | In Review |
| **Phase** | Operations |
| **Assignee** | ann |
| **Dependencies** | none |
| **Estimated effort** | M |

## Problem

Seeing what runs INSIDE a pod meant hand-ssh. First user: the live 4090 pod while orion and neo measure on it.

## Success criteria

- [x] `water-spider ps <pod> [--host H --pod-port P]`: user/pid/elapsed/%CPU/RSS/cmdline, GPU VRAM joined by pid, listeners flagged LOOPBACK vs PUBLIC, cgroup mem/cpu (not host /proc/meminfo).
- [x] `water-spider gpu <pod> [--watch N>=5]`: util, VRAM, power, temp, clocks, per-process VRAM.
- [x] Read-only remote script (no writes, no installs, no /proc/*/environ); absent tools degrade.
- [x] One ssh round trip per tick, ControlMaster in a private 0700 dir, BatchMode.
- [x] Secrets redacted remotely and locally.
- [x] Risk flags: public non-sshd listener, unidentifiable/orphaned GPU process, disk > 90%, VRAM > 95%.
- [x] Fake-backed tests + opt-in docker rehearsal (`tests/docker-rehearsal.sh`).
- [x] nvidia-smi fields start with the MCP `gpu_status` set so both surfaces agree.

Follow-up: expose ps/gpu/watch as MCP control-profile tools over ssh (WATERS-028 item).
