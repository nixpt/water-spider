---
name: water-spider-repo
purpose: 
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

## Build / Test

- Syntax: `bash -n bin/water-spider tests/run.sh tests/fakes/*`
- Static analysis: `shellcheck bin/water-spider tests/run.sh tests/fakes/*`
- Deterministic suite: `./tests/run.sh` (no network, credentials, pods, or real
  SSH/process operations)

## Architecture Map

- `bin/water-spider`: transport-agnostic Bash CLI; all product behavior lives
  here and delegates to `runpodctl`, SSH, or conditional GraphQL via curl.
- `tests/`: command-level harness with PATH-injected external-command fakes.
- `.jagent/planning/`: backlog, roadmap, execution rules, and ticket evidence.
- `.github/workflows/`: ShellCheck/test CI and semantic-version release job.

## Memory

Decisions, blockers, and constraints are captured in `.dejavue/` — run
`dejavue context` for the boot packet and `dejavue recall <query>` to search.
