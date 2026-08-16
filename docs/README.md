# water-spider documentation

The root [`README.md`](../README.md) is the project overview and shortest safe
path. Start with the user guides, then use the maintainer references as needed.

## User guides

- [`getting-started.md`](getting-started.md) — prerequisites, authentication,
  installation choices, and a first safe lifecycle.
- [`cli-reference.md`](cli-reference.md) — complete command syntax, behavior,
  side effects, and exit expectations.
- [`configuration.md`](configuration.md) — environment variables, credentials,
  private registries, cache directories, and snapshot state.
- [`workflows.md`](workflows.md) — task-oriented examples and recovery steps for
  ambiguous creation, SSH, tunnels, and teardown.

## Maintainer and operational references

- [`architecture.md`](architecture.md) — command boundaries, state, safety
  invariants, and repository layout.
- [`operations.md`](operations.md) — create-to-teardown workflow, credentials,
  live-validation status, and incident-safe practices.
- [`testing.md`](testing.md) — deterministic suite, ShellCheck, CI, and the line
  between mocked and billable verification.
- [`releasing.md`](releasing.md) — version surface, tags, workflows, images, and
  the remaining initial-release work.
- [`repository-operations.md`](repository-operations.md) — `gh-ruleset`,
  `git-ops`, release bootstrap, audits, and branch maintenance.
- [`../docker/README.md`](../docker/README.md) — image variants, build details,
  RunPod templates, and recorded image-validation evidence.
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — contribution and agent workflow.
- [`../STATE.md`](../STATE.md) — detailed current state and historical findings.

Planning lives separately under [`.jagent/planning/`](../.jagent/planning/).
Durable architectural context lives under [`.dejavue/`](../.dejavue/).
The repository-native agent workflow lives in
[`../.jagent/skills/water-spider/`](../.jagent/skills/water-spider/SKILL.md).
