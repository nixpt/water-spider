# water-spider

<p align="center">
  <img src="assets/banner-1280x425.png" alt="Water Spider — GPU lifecycle orchestration" width="100%">
</p>

<p align="center">
  Cost-safe RunPod GPU lifecycle orchestration from one small CLI.
</p>

Water-spider creates, inspects, connects to, tunnels into, snapshots, and tears
down RunPod pods. It uses `runpodctl` for standard operations and selects the
RunPod GraphQL API only when creation needs constraints the CLI does not expose.

Its primary invariant is cost safety: creation is never blindly retried, an
idempotency key can replay a prior successful request, and teardown is not
reported as successful until a fresh provider query confirms the pod is gone.

## Quick start

```sh
git clone https://github.com/nixpt/water-spider.git
cd water-spider
export PATH="$PWD/bin:$PATH"

runpodctl doctor
water-spider status
water-spider gpus --available
```

Create a pod only after setting a budget and teardown deadline:

```sh
water-spider create \
  --image IMAGE \
  --gpu "GPU NAME" \
  --idempotency-key "experiment-$(date +%Y%m%d)"

water-spider list
water-spider connect POD-ID
water-spider tunnel POD-ID --port 8080:8080

# Pull anything worth keeping, then remove the billable resource.
water-spider teardown POD-ID
water-spider list
```

Start with the [getting-started guide](docs/getting-started.md) for
prerequisites, authentication, Docker use, and the first safe lifecycle.

## What it can do

| Area | Commands |
|---|---|
| Provision and inspect | `create`, `list`, `status`, `get`, `gpus` |
| Reach a pod | `connect`, `tunnel`, `gui` |
| Move and preserve work | `send`, `receive`, `snapshot`, `teardown --pull` |
| Run inference | `recipe list`, `recipe serve` |
| Fleet integration | `scaffold` (optional and nixpt-internal) |

Agents can also use the read-only [`water-spider-mcp`](docs/mcp.md) server.
It provides a local control profile over stdio and an in-image node profile over
loopback Streamable HTTP, designed to be reached through `water-spider tunnel`.
For short-lived coding workers, the
[Mayfly + OpenCode guide](docs/mayfly-opencode.md) connects a local harness to
a tool-capable llama.cpp endpoint on the v2 image without exposing a pod port.

See the [CLI reference](docs/cli-reference.md) for syntax, flags, environment
variables, side effects, and examples for every command.

## Installation choices

- **Local shell:** put `bin/` on `PATH`; requires `runpodctl`, `ssh`, `jq`, and
  `pgrep`. GraphQL-only create options additionally require `curl`.
- **Container CLI:** run `ghcr.io/nixpt/water-spider:latest` or
  `nixpt/water-spider:latest` from your machine.
- **CPU control pod:** use `nixpt/water-spider:pod` as a persistent orchestrator
  that manages other pods.
- **GPU control pod:** use `nixpt/water-spider:v2` when the orchestrator also
  needs CUDA llama.cpp inference.

The [Docker image guide](docker/README.md) explains the three image roles,
builds, public RunPod templates, and verified behavior.
For the GPU image, follow the dedicated
[v2 llama.cpp, GPU, and GUI guide](docs/v2-gpu-guide.md).

## Safety boundaries

- A create request is attempted once; ambiguous results require inspection.
- Use `--idempotency-key` anywhere a request may be repeated.
- Pull valuable artifacts before teardown; pod storage is not a backup.
- `snapshot` records a lightweight model/provenance manifest, not disk bytes.
- Live RunPod usage is billable. Tests never use credentials or real resources.

Read [common workflows](docs/workflows.md) before automating creation,
inference, file transfer, snapshots, or teardown. Configuration, credential,
cache, and private-image behavior is covered in
[configuration and state](docs/configuration.md).
```sh
docker build -f Dockerfile.v2 -t nixpt/water-spider:v2 \
  --build-arg CUDA_ARCHS="75;80;86;89;90;120" .   # T4 through Blackwell
docker build -f Dockerfile.train -t nixpt/water-spider:train .
```

After SSH-ing into a v2 pod, run `water-spider-pod-init` first (GPU
clock-lock + verify, same reproducible-benchmark discipline zorro's own
`zorro-pod-init` uses — generic GPU-ops knowledge, not zorro-specific
code). Then:

```sh
hf download <repo> <file.gguf> --local-dir /workspace/scratch/models
llama-server -m /workspace/scratch/models/<file.gguf> --port 8080 -ngl 999
```

`llama-cli`, `llama-server`, `llama-quantize`, `llama-bench`, and
`llama-gguf-split` are all on `PATH`.

See [`docker/README.md`](docker/README.md) for the full breakdown of all
four images (what's in each, why they're separate, the `docker/*.sh`
helper scripts, live RunPod template ids, and the "verified at authoring
time" test log for each).

## Subcommands

- **`create`** — guards the historical flaky-create-makes-billed-dupes
  trap: one attempt, verify by `pod list` after, never blind-retry.
  `--idempotency-key KEY` makes retries safe — a retried `create` with the
  same key replays the same pod instead of billing a second one (local
  ledger + `mkdir`-atomic lock). `--min-download`/`--min-upload`/
  `--cuda-versions`/`--data-center`/`--country`/`--registry-auth-id` reach
  GraphQL-only fields `runpodctl`'s own CLI doesn't expose at all (checked:
  `runpodctl create pod --help`) — a bandwidth floor and an allowed-driver-
  version filter enforced at creation time instead of discovered (and paid
  for) after the fact, and a private-registry credential so `--image` can
  point at a private repo. `--registry-auth-id` defaults from
  `$WATER_SPIDER_REGISTRY_AUTH_ID` — see
  [`docker/create-registry-auth.sh`](docker/create-registry-auth.sh) to
  register a Docker Hub credential with RunPod and get an id. Live-tested
  end to end: created a real pod against a private image with this set,
  confirmed via SSH it actually pulled.
- **`list`** / **`status`** (balance + live spend/hr) / **`get`**
- **`connect`** — resolves SSH connection info and prints it, with a proxy
  fallback.
- **`send`** / **`receive`** — prints the paired `runpodctl send`/`receive`
  croc commands for moving files to/from a pod.
- **`tunnel`** — SSH local-port-forward so a pod-side service (e.g. a model
  server) answers on `localhost` on YOUR machine. A local coding harness
  points at `http://localhost:8080/v1` and transparently reaches the pod's
  GPU. Needs only port 22 — no extra RunPod port declarations.
- **`recipe serve <pod-id> <model-path> [--engine ...] [--port N]`** —
  launch a model server on the pod, auto-tunnel it, print the ready local
  URL. The "test model X locally, from a harness on MY machine" workflow
  in one command.
- **`gui [--x11|--trusted] [--display N] -- <command...>`** — SSH X11
  forwarding: a GUI app launched on the pod renders in a window on YOUR
  machine. Prefers [`xpra`](https://xpra.org/) (SSH-transport-native,
  survives a dropped connection — `x11docker`'s own pick for seamless-window
  mode) when installed locally; falls back to raw `ssh -X`/`-Y` otherwise.
  Needs `xauth`/`xpra` on the pod side and `X11Forwarding yes` in sshd.
- **`snapshot <pod-id> [-o FILE]`** — a lightweight config MANIFEST (model
  filenames + image provenance), not a filesystem backup — the pod→home
  transport is too slow for that.
- **`teardown <pod-id>`** — the full checklist: reminds you to pull results
  first, confirms before deleting, deletes, then VERIFIES the pod is
  actually gone rather than trusting the delete call's exit code.
- **`gpus [--available]`** — `runpodctl gpu list`, filtered/formatted.
- **`scaffold <name> [flags...]`** — OPTIONAL, fleet-internal only: a thin
  passthrough to `foreman-scaffold` (needs a sibling
  [`jokersquad`](https://github.com/nixpt/jokersquad) checkout). Everything
  else above works standalone with no other nixpt-fleet repo present.

## Design notes

- One transport-agnostic core script, not a wrapper generator — every
  subcommand shells out to `runpodctl` or the RunPod GraphQL API directly.
- Cost-safety first: anything that could spend real money against the live
  API gets a single, verified attempt — never a blind retry loop.
- `set -euo pipefail` throughout, with the classic `out="$(cmd)"; rc=$?`
  trap deliberately avoided (`-e` exits before `rc=$?` ever runs, silently
  swallowing the error) — every capture uses `|| rc=$?` or
  `if ! var="$(...)"` instead.

## Status

See `STATE.md` for current status and `.jagent/planning/ROADMAP.md` for
the plan.

## Documentation

- [Getting started](docs/getting-started.md)
- [CLI reference](docs/cli-reference.md)
- [Common workflows and troubleshooting](docs/workflows.md)
- [MCP server for local agents and tunneled pod tools](docs/mcp.md)
- [v2 GPU, llama.cpp, and GUI applications](docs/v2-gpu-guide.md)
- [Short-lived agents with Mayfly and OpenCode](docs/mayfly-opencode.md)
- [Configuration, credentials, and local state](docs/configuration.md)
- [Operations and live-validation status](docs/operations.md)
- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Releasing](docs/releasing.md)
- [Repository operations](docs/repository-operations.md)

Current evidence and remaining work are recorded in [STATE.md](STATE.md) and
[the project roadmap](.jagent/planning/ROADMAP.md).

## Agent skill

Agents can use the repository-native [`water-spider` skill](.jagent/skills/water-spider/SKILL.md)
for lifecycle classification, cost authorization, safe retries, artifact
preservation, teardown verification, and routing to the appropriate guide.
Invoke it as `$water-spider` in hosts that discover `.jagent/skills/`.

## Contributing

Contributions from humans and coding agents are welcome. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before starting, especially the rules for
billable tests, secrets, teardown verification, and ticket worktrees.

## License

Available under either the [MIT License](LICENSE-MIT) or the
[Apache License 2.0](LICENSE-APACHE), at your option.
