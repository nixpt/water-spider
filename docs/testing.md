# Testing

## Deterministic verification

```sh
bash -n bin/water-spider tests/run.sh tests/fakes/* docker/*.sh
shellcheck bin/water-spider tests/run.sh tests/fakes/* docker/*.sh
./tests/run.sh
git diff --check
```

The suite currently runs 29 cases. It covers every CLI dispatch path plus API
failure, malformed JSON, ambiguous SSH data, GraphQL escaping and validation,
transport errors, idempotent replay, and failed teardown verification.

Fakes for `runpodctl`, `ssh`, `curl`, `pgrep`, `sleep`, `column`, and the
optional scaffold command are placed first on `PATH`. Tests isolate `HOME` and
`XDG_CACHE_HOME` under a temporary directory. They must not contact RunPod,
open SSH connections, kill real processes, or read developer credentials.

## CI

`.github/workflows/ci.yml` runs pinned ShellCheck and the command suite on every
push and pull request. Local verification should use ShellCheck 0.10.0 until CI
is intentionally upgraded.

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
