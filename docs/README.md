# water-spider documentation

The root [`README.md`](../README.md) is the quick start. These documents cover
the details needed to maintain and operate the project:

- [`architecture.md`](architecture.md) — command boundaries, state, safety
  invariants, and repository layout.
- [`operations.md`](operations.md) — create-to-teardown workflow, credentials,
  live-validation status, and incident-safe practices.
- [`testing.md`](testing.md) — deterministic suite, ShellCheck, CI, and the line
  between mocked and billable verification.
- [`releasing.md`](releasing.md) — version surface, tags, workflows, images, and
  the remaining initial-release work.
- [`../docker/README.md`](../docker/README.md) — image variants, build details,
  RunPod templates, and recorded image-validation evidence.
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — contribution and agent workflow.
- [`../STATE.md`](../STATE.md) — detailed current state and historical findings.

Planning lives separately under [`.jagent/planning/`](../.jagent/planning/).
Durable architectural context lives under [`.dejavue/`](../.dejavue/).
