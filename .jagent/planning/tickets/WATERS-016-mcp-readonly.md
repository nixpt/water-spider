# WATERS-016 — Add read-only control and node MCP profiles

| Field | Value |
|-------|-------|
| **ID** | WATERS-016 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | MCP foundation |
| **Assignee** | codex |
| **Dependencies** | WATERS-014, WATERS-015 |
| **Estimated effort** | M |

## Problem

Agents can invoke the Bash CLI, but there is no typed MCP surface for local
RunPod inspection or direct read-only inspection inside a water-spider image.
Adding create/delete immediately would outrun the project's cost-safety model.

## Success criteria

- [x] One native binary supports stdio and Streamable HTTP.
- [x] Control and node profiles expose separate typed tool catalogs.
- [x] The control profile wraps only read-only CLI commands without a shell.
- [x] The node profile exposes only fixed local inspection operations.
- [x] HTTP rejects non-loopback listeners and is documented for SSH tunneling.
- [x] All Docker variants include the binary; control images can start it opt-in.
- [x] Real MCP client tests cover both profiles and transports.
- [x] CI enforces Rust formatting, tests, and Clippy.

## Non-goals

- Pod creation, teardown, model downloads, service mutation, or arbitrary shell.
- A public MCP endpoint or OAuth deployment.
- Claiming a container build or live pod validation without that evidence.

## Resolution

Added a Rust `water-spider-mcp` binary using the official SDK. The control
profile exposes five read-only RunPod/SSH discovery tools; the node profile
exposes three fixed local inspection tools. Added stdio and stateless loopback
Streamable HTTP, protocol-level tests, static multi-stage image packaging, an
opt-in pod startup hook, CI coverage, and user documentation.
