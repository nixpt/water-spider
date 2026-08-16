# WATERS-002 — Add a mocked command-level test harness

| Field | Value |
|-------|-------|
| **ID** | WATERS-002 |
| **Priority** | P0 |
| **Status** | Done |
| **Phase** | Core health |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-001 |
| **Estimated effort** | L |

## Problem

The CLI has no automated tests. Parsing, idempotency, tunnel PID tracking, snapshot generation, and deletion verification currently depend on manual inspection or access to a billable RunPod pod.

## Reproduction

1. Run `find tests -type f` from the repository root.
2. Observe that no test directory or executable test suite exists.
3. Inspect `.github/workflows/ci.yml`; it runs static analysis only.

## Success criteria

- [x] A deterministic test command exercises every subcommand without network access or account credentials.
- [x] Tests replace `runpodctl`, `ssh`, `curl`, `pgrep`, and destructive process operations with controlled fakes.
- [x] Failure cases cover malformed JSON, failed API calls, ambiguous SSH information, duplicate idempotency keys, and failed teardown verification.
- [x] CI runs the suite on every push and pull request.

## Technical approach

- Choose Bats or a dependency-free shell harness and document the single test command.
- Place fake executables first on `PATH` and isolate cache/output under a temporary directory.
- Build fixtures for known `runpodctl` JSON shapes and GraphQL responses.
- Assert exit status, stdout/stderr, side effects, and refusal to retry or delete unsafely.

## Files to modify

- `tests/` — add harness, fakes, fixtures, and command tests.
- `.github/workflows/ci.yml` — execute the suite.
- `README.md` — document local testing.

## Non-goals

- Spending money or contacting the live RunPod API in routine CI.

## Resolution

Added a dependency-free command harness with controlled fakes for all external integrations. It exercises every dispatch path plus malformed JSON, API failure, ambiguous SSH data, idempotent replay, and unverifiable deletion. The suite reports 22 passing cases, runs in CI, and the README documents local execution. ShellCheck 0.10.0 and `bash -n` also pass across the CLI, harness, and fake executables.
