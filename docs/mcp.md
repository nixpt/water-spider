# MCP server

`water-spider-mcp` is a native MCP server for agents. The first implementation
is intentionally read-only: it establishes typed tools, profile isolation, and
both local and tunneled transports without allowing an agent to create or
delete a billable resource.

## Profiles

The control profile runs beside an agent with the same RunPod configuration as
the CLI:

| Tool | Purpose |
|---|---|
| `account_status` | Balance, current spend, and pod count |
| `pods_list` | Visible pods and their state |
| `pod_get` | One exact provider pod record |
| `gpus_list` | GPU catalog, optionally available-only |
| `pod_connect_info` | Resolved SSH command without opening it |

The node profile runs inside `:pod` or `:v2` and has no RunPod lifecycle tools:

| Tool | Purpose |
|---|---|
| `node_status` | Image metadata, host, kernel, and workspace disk |
| `gpu_status` | Fixed read-only `nvidia-smi` query |
| `models_list` | Names and sizes in the configured model directory |

Neither profile exposes arbitrary shell execution. Tool results are JSON text
containing explicit `ok`, exit, stdout, and stderr fields where applicable.

## Local agent over stdio

Build and register the binary:

```sh
cargo build --manifest-path mcp/Cargo.toml --release
```

Example Codex configuration:

```toml
[mcp_servers.water_spider]
command = "/path/to/water-spider/mcp/target/release/water-spider-mcp"
args = ["--profile", "control", "--transport", "stdio"]
env = { WATER_SPIDER_BIN = "/path/to/water-spider/bin/water-spider" }
```

The subprocess inherits the agent host's RunPod and SSH environment. Protocol
traffic uses stdout; diagnostics use stderr.

## In-image server through an SSH tunnel

All three Docker variants contain `/usr/local/bin/water-spider-mcp`. On a
control/GPU pod, start the node profile automatically by setting the template
environment variable:

```text
WATER_SPIDER_MCP_ENABLE=1
```

The startup hook serves `http://127.0.0.1:8765/mcp` inside the pod. The binary
rejects a non-loopback listener. Forward it locally:

```sh
water-spider tunnel POD-ID --port 8765:8765
```

Then configure an MCP client for Streamable HTTP at
`http://127.0.0.1:8765/mcp`. No public RunPod port is needed. The SSH tunnel is
the network boundary; stop it with `water-spider tunnel POD-ID --stop`.

To start manually after SSH:

```sh
water-spider-mcp --profile node --transport http --listen 127.0.0.1:8765
```

The CPU control image may explicitly use `WATER_SPIDER_MCP_PROFILE=control` when
RunPod credentials are intentionally present, but node remains the default.

## Security boundary

- Streamable HTTP is loopback-only and intended for SSH forwarding.
- Control and node tool catalogs are separate; clients never receive hidden
  lifecycle tools in the node profile.
- Subprocess arguments are passed directly, never through a shell.
- Node commands are fixed by the implementation.
- Tool annotations describe read-only behavior, but enforcement comes from the
  available handlers, not annotations.
- This milestone does not expose `create`, `teardown`, model download, service
  start/stop, or arbitrary execution.

Billable tools require a later lease design with a stable idempotency key,
price/runtime constraints, durable deadline enforcement, artifact policy, and
independent teardown verification.

## Development

```sh
cargo fmt --manifest-path mcp/Cargo.toml --check
cargo test --manifest-path mcp/Cargo.toml --locked
cargo clippy --manifest-path mcp/Cargo.toml --all-targets --locked -- -D warnings
```

Tests use real MCP clients over stdio and Streamable HTTP, verify that profiles
do not leak each other's tools, prove subprocess arguments do not pass through
a shell, and reject public HTTP listeners. Sandboxes that prohibit loopback
sockets skip only the HTTP round trip; CI exercises it normally.
