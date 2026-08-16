# Testing

## Deterministic verification

```sh
bash -n bin/water-spider scripts/bump-version.sh tests/run.sh tests/release.sh tests/fakes/* docker/*.sh integrations/mayfly-opencode/water-spider-mayfly
shellcheck bin/water-spider scripts/bump-version.sh tests/run.sh tests/release.sh tests/fakes/* docker/*.sh integrations/mayfly-opencode/water-spider-mayfly
./tests/run.sh
./tests/release.sh
cargo fmt --manifest-path mcp/Cargo.toml --check
cargo test --manifest-path mcp/Cargo.toml --locked
cargo clippy --manifest-path mcp/Cargo.toml --all-targets --locked -- -D warnings
git diff --check
```

The suite currently runs 32 cases. It covers every CLI dispatch path plus API
failure, malformed JSON, ambiguous SSH data, GraphQL escaping and validation,
transport errors, idempotent replay, failed teardown verification, and the
Mayfly/OpenCode endpoint preflight. Live model qualification remains opt-in.

The release test creates an isolated temporary Git repository. It proves that a
commit tagged with the current `VERSION` is a no-op and that the first later fix
selects the next patch version; it never pushes or contacts GitHub.

Fakes for `runpodctl`, `ssh`, `curl`, `pgrep`, `sleep`, `column`, and the
optional scaffold command are placed first on `PATH`. Tests isolate `HOME` and
`XDG_CACHE_HOME` under a temporary directory. They must not contact RunPod,
open SSH connections, kill real processes, or read developer credentials.

The MCP suite starts real stdio and Streamable HTTP clients against the server,
checks profile-specific tool discovery, and calls the control adapter through a
fake `water-spider` executable. If the host sandbox prohibits loopback binds,
only the HTTP transport case is skipped; CI runs the complete protocol suite.

## CI

`.github/workflows/ci.yml` runs ShellCheck 0.10.0, the command suite, and Rust
format/test/clippy checks on every push and pull request. Upgrade pinned tools
and local expectations together.

## Live verification

Mocks prove orchestration and failure handling, not external interface reality.
A live campaign requires:

1. an authorized maximum cost and hard teardown deadline;
2. a unique idempotency key;
3. sanitized command/output evidence;
4. immediate teardown on the first blocking failure;
5. a fresh final list proving the pod is absent.

Update `STATE.md`, WATERS-003, and source caveats only for paths actually
observed live.
