---
name: water-spider
purpose: Cost-safe RunPod GPU lifecycle CLI and published control-pod image family
dcp: DCP/1.0
---

# Context

<!-- The DCP instruction layer: what an agent should *do* in this repo.
     Source of truth — adapters (CLAUDE.md / AGENTS.md / …) are generated
     from this file via `dejavue export --target <tool>`. -->

## Operating Rules

- Cost safety is the primary invariant: never blindly retry pod creation and
  never trust deletion without independently verifying the pod is absent.
- Run `.jagent/planning/` tickets in dedicated branches and worktrees; reproduce
  each ticket before changing code.
- Do not use a live RunPod resource without an explicit cost cap and teardown
  deadline.
- Never turn mocked behavior into a claim of live RunPod verification; keep the
  evidence boundary explicit in `STATE.md` and `docs/operations.md`.

## Build / Test

- Syntax: `bash -n bin/water-spider scripts/bump-version.sh tests/run.sh tests/release.sh tests/fakes/* docker/*.sh`
- Static analysis: `shellcheck bin/water-spider scripts/bump-version.sh tests/run.sh tests/release.sh tests/fakes/* docker/*.sh`
- Deterministic suite: `./tests/run.sh` (no network, credentials, pods, or real
  SSH/process operations)

## Architecture Map

- `bin/water-spider`: transport-agnostic Bash CLI; all product behavior lives
  here and delegates to `runpodctl`, SSH, or conditional GraphQL via curl.
- `tests/`: command-level harness with PATH-injected external-command fakes.
- `.jagent/planning/`: backlog, roadmap, execution rules, and ticket evidence.
- `.github/workflows/`: ShellCheck/test CI and semantic-version release job.
- `docs/`: architecture, operations, testing, and release guides.
- `docs/repository-operations.md`: release bootstrap, ruleset policy, git-ops,
  audits, and branch maintenance.
- `docker/` + `Dockerfile*`: one-shot CLI, CPU control pod, and CUDA/llama.cpp
  GPU control pod; `docker/README.md` owns image-specific evidence.

## Memory

Decisions, blockers, and constraints are captured in `.dejavue/` — run
`dejavue context` for the boot packet and `dejavue recall <query>` to search.
