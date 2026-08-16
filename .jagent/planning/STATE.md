# Planning state — water-spider

**Updated:** 2026-08-16
**Milestone focus:** M1 — operational validation

**Implementation:** standalone 863-line Bash CLI with create/list/status/get,
SSH connection and tunnels, transfer guidance, serving recipes, GUI forwarding,
manifest snapshots, verified teardown, GPU discovery, and optional fleet
scaffolding.

**Quality:** ShellCheck 0.10.0 clean; 29 deterministic command tests passing.
GraphQL inputs are locally validated and safely encoded.

**Live evidence:** create, SSH, private-registry pull, GPU initialization and
inference, local tunnel, HTTP completion, teardown, and independent absence
verification. Transfer, recipe-wrapper, GUI, and snapshot paths remain open in
WATERS-003.

**Release:** `origin` is the public `nixpt/water-spider` repository and project
work has been pushed. WATERS-005 remains open only for the initial project
version surface, tag/release, and subsequent bump proof.

**Documentation:** root quick start plus `docs/` architecture, operations,
testing, and release guides; `docker/README.md` owns image details.

**Branch:** `ticket/waters-009-docs-refresh`
