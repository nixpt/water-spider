# Configuration and local state

Water-spider is configured through the RunPod CLI, four optional environment
variables, and small local state directories. It does not maintain a separate
global configuration file.

## Authentication

`runpodctl doctor` normally stores the RunPod API key in
`~/.runpod/config.toml`. `RUNPOD_API_KEY` can instead scope a key to the current
process. Do not store credentials in this repository.

## Environment variables

| Variable | Purpose |
|---|---|
| `WATER_SPIDER_TEMPLATE_ID` | Default template for `create`; takes precedence over the image default |
| `WATER_SPIDER_IMAGE` | Default image when no template ID is configured |
| `WATER_SPIDER_SSH_KEY` | SSH private-key path; defaults to `~/.ssh/runpod` |
| `WATER_SPIDER_REGISTRY_AUTH_ID` | RunPod registry credential used for private-image creation |

Command-line values override the corresponding create defaults. For example:

```sh
export WATER_SPIDER_IMAGE=nixpt/water-spider:v2
export WATER_SPIDER_SSH_KEY="$HOME/.ssh/runpod"
water-spider create --gpu "GPU NAME" --idempotency-key gpu-control-01
```

If `WATER_SPIDER_TEMPLATE_ID` is set, unset it before expecting
`WATER_SPIDER_IMAGE` to become the default.

## Private registries

RunPod needs its own registry-auth record to pull a private image. The helper
[`docker/create-registry-auth.sh`](../docker/create-registry-auth.sh) creates
that record and prints its ID. Store the ID—not the Docker Hub token—in
`WATER_SPIDER_REGISTRY_AUTH_ID`, or pass `--registry-auth-id` explicitly.

Registry authentication selects the GraphQL create path, which requires
`curl`. Keep Docker tokens and RunPod API keys out of shell traces and logs.

## Local state

State follows `XDG_CACHE_HOME`, falling back to `~/.cache`:

```text
${XDG_CACHE_HOME:-$HOME/.cache}/water-spider/
├── idempotency/   # keys mapped to successfully created pod IDs
└── tunnels/       # exact SSH tunnel PIDs tracked per pod
```

The idempotency directory uses an atomic lock so concurrent requests with the
same key cannot both create pods. Do not delete an entry merely to force a
retry; first prove whether the original pod still exists.

Tunnel state lets `tunnel --stop` and `teardown` target the process started for
that pod without killing unrelated SSH sessions. Stale PID files are detected
rather than trusted blindly.

## Snapshot manifests

`snapshot` writes JSON containing model filenames and image provenance. A later
`create --restore FILE` replays the model acquisition plan and checks image
provenance. The file is not a filesystem archive and contains no model bytes.

Choose an explicit output location if the manifest is part of an experiment
record:

```sh
water-spider snapshot POD-ID -o records/run-01.snapshot.json
```
