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

## Documentation

- [Getting started](docs/getting-started.md)
- [CLI reference](docs/cli-reference.md)
- [Common workflows and troubleshooting](docs/workflows.md)
- [MCP server for local agents and tunneled pod tools](docs/mcp.md)
- [v2 GPU, llama.cpp, and GUI applications](docs/v2-gpu-guide.md)
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
