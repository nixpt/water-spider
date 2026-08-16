# water-spider

A thin RunPod GPU-pod-lifecycle CLI built on `runpodctl` (and the RunPod
GraphQL API for the fields the CLI doesn't expose). Named for the
lean-manufacturing "water spider" role: ferries supplies so a workstation
never has to leave its post — here, automates the provision / connect /
tunnel / teardown dance so it's never hand-run.

Not tied to any specific image — defaults to the `nixpt/zorro` image family
via `WATER_SPIDER_TEMPLATE_ID`/`WATER_SPIDER_IMAGE`, but works with any
RunPod pod template.

## Install

```sh
git clone https://github.com/nixpt/water-spider.git
export PATH="$PWD/water-spider/bin:$PATH"
water-spider --help
```

Requires `runpodctl`, `ssh`, `jq`, `pgrep` on PATH, and a RunPod API key in
`~/.runpod/config.toml` (or `$RUNPOD_API_KEY`). Falls back to
[`bucket-bridge`](https://github.com/nixpt/buckets) to JIT-provision a
missing dependency like `jq` rather than hard-failing, if `bucket-bridge`
is itself available.

### Or: Docker

A separate, lightweight image ships the CLI itself — no CUDA, no model
weights, distinct from the `nixpt/zorro` inference image. Published on
Docker Hub as [`nixpt/water-spider`](https://hub.docker.com/r/nixpt/water-spider).
~179MB: base + `runpodctl` (pinned release, sha256-verified at build time)
+ `jq` + `openssh-client` + a handful of small CLI deps.

```sh
docker pull nixpt/water-spider          # or: docker build -t nixpt/water-spider .
docker run --rm -it \
  -v "$HOME/.runpod:/root/.runpod:ro" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -p 8080:8080 \
  nixpt/water-spider gpus --available
```

`gui`'s `xpra` path isn't baked in by default (keeps the image small — the
script already falls back to raw `ssh -X`/`-Y`); build with
`--build-arg INCLUDE_XPRA=1` to include it. See the `Dockerfile` header
for the full run-flag rundown (mounting the X socket for local X11
forwarding, etc).

### Or: a RunPod "control pod"

Both options above run water-spider on YOUR machine. For a persistent
orchestrator that lives in RunPod's own network instead — so pods you
manage stay reachable without a laptop left open — there's a separate
[`Dockerfile.runpod`](Dockerfile.runpod) variant (published as
`nixpt/water-spider:pod`) built on RunPod's own base image (same
self-healing SSH setup validated for `nixpt/zorro`'s image), with
water-spider preinstalled on `PATH` instead of as the `ENTRYPOINT` — the
container stays alive as a normal SSH-reachable pod; you `ssh` in and run
`water-spider ...` by hand to manage your *other* pods.

Published as a public RunPod Template — search "water-spider" in the
RunPod console, or deploy straight from
[`docker/create-runpod-template.sh`](docker/create-runpod-template.sh)
(`PUBLISH_PUBLIC=1` to republish; RunPod templates can't be edited via
PATCH once public — a platform quirk documented in that script's header —
so republishing means delete + recreate, not update).

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
