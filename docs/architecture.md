# Architecture

water-spider is one strict-mode Bash program with external command boundaries,
not a daemon or API reimplementation.

## Runtime flow

```text
user / local harness
        |
        v
bin/water-spider
  |-- runpodctl -------- standard pod, user, GPU, SSH-info operations
  |-- RunPod GraphQL --- creation fields absent from runpodctl
  |-- ssh -------------- commands, GUI forwarding, and local tunnels
  `-- local state ------ idempotency ledgers and tracked tunnel PIDs
```

The normal creation path stays on `runpodctl`. GraphQL is selected only for
bandwidth, CUDA, location, or private-registry constraints that `runpodctl`
does not expose. GraphQL strings are encoded through `jq`, constrained values
are validated before the request, and `curl` is required only on that path.

## Local state

- `${XDG_CACHE_HOME:-$HOME/.cache}/water-spider/idempotency/` maps a caller's
  idempotency key to the pod created by the first successful request.
- `${XDG_CACHE_HOME:-$HOME/.cache}/water-spider/tunnels/` stores the exact SSH
  tunnel PID per pod so teardown does not kill unrelated SSH processes.
- Snapshot files are lightweight JSON manifests. They record model filenames
  and image provenance, not model bytes or a restorable filesystem image.

## Safety invariants

1. A billable create is attempted once and never blindly retried.
2. An idempotency key is checked before and under an atomic filesystem lock.
3. Pod deletion is not success until a fresh list confirms absence.
4. A failed verification is reported as unknown, never as a false all-clear.
5. Pod storage is transient and never the repository or backup of record.
6. Deterministic tests never use credentials, network access, real SSH, or real
   process termination.

## Repository map

- `bin/water-spider` — all CLI behavior and dispatch.
- `tests/` — command-level harness and PATH-injected fakes.
- `docker/` and `Dockerfile*` — one-shot, CPU-control, and GPU-control images.
- `.github/workflows/` — static analysis/tests and release automation.
- `.jagent/planning/` — tickets, sequence, and execution discipline.
- `.dejavue/` — portable context, decisions, state, handoff, and fallback CLI.
