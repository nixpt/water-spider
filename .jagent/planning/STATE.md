# Planning state — water-spider

**Updated:** 2026-08-16
**Milestone focus:** M1 — operational validation

**Implementation:** standalone 800+ line Bash CLI with create/list/status/get,
SSH connection and tunnels, transfer guidance, serving recipes, GUI forwarding,
manifest snapshots, verified teardown, GPU discovery, and optional fleet
scaffolding.

**Quality:** ShellCheck 0.10.0 clean; 29 deterministic command tests passing.
GraphQL inputs are locally validated and safely encoded.

**Open:** WATERS-003 needs authorization for a capped billable pod. WATERS-005
needs repository-owner approval, an initial version choice, and GitHub remote
configuration. The current checkout has no `origin`, so milestone commits
cannot yet be pushed.

**Branch:** `ticket/waters-006-metadata`
