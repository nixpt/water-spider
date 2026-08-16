# WATERS-014 — Restructure the README and add user-facing guides

| Field | Value |
|-------|-------|
| **ID** | WATERS-014 |
| **Priority** | P2 |
| **Status** | Done |
| **Phase** | Project metadata |
| **Assignee** | codex |
| **Dependencies** | WATERS-009, WATERS-011 |
| **Estimated effort** | M |

## Problem

The README mixes onboarding, command reference, image implementation detail,
and maintainer notes. The documentation set has no complete CLI reference or
task-oriented user guides, making safe first use harder than necessary.

## Success criteria

- [x] The README becomes a concise overview and navigation surface.
- [x] A getting-started guide covers installation, authentication, and first use.
- [x] A CLI reference documents every public command and option family.
- [x] Configuration and workflow guides cover local state, credentials, common
      tasks, and failure recovery.
- [x] The documentation index separates user and maintainer material.
- [x] Existing release-test documentation follows the version-independent test.

## Resolution

Replaced the monolithic README with a safety-led quick start and documentation
map. Added getting-started, CLI-reference, configuration, and workflow guides;
updated the docs index and corrected the release-test description.
