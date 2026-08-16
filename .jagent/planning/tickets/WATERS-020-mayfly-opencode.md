# WATERS-020 — Integrate Mayfly and OpenCode with v2 inference

| Field | Value |
|-------|-------|
| **ID** | WATERS-020 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | Agent runtime |
| **Assignee** | codex |
| **Dependencies** | WATERS-019 |
| **Estimated effort** | M |

## Problem

The v2 image can serve llama.cpp, but local short-lived agents have no stable,
documented path from Mayfly through OpenCode to its tunneled inference API.

## Success criteria

- [x] Add a loopback-only llama.cpp recipe with tool calling enabled.
- [x] Add a checked OpenCode provider configuration and Mayfly launcher.
- [x] Add a constrained, opt-in live qualification fixture.
- [x] Document ownership boundaries, prerequisites, safety limits, and teardown.
- [x] Cover the endpoint preflight and recipe dispatch deterministically.

## Resolution

Added `llama-agent`, a local integration wrapper and provider configuration,
an isolated qualification fixture, deterministic checks, and an operator guide.
Mayfly and OpenCode remain replaceable host dependencies; no harness was forked
and no live or billable resource was used during implementation.
