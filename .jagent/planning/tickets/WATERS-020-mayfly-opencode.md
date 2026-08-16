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
- [x] Correct argument and failure-propagation defects found during live use.

## Resolution

Added `llama-agent`, a local integration wrapper and provider configuration,
an isolated qualification fixture, deterministic checks, and an operator guide.
Mayfly and OpenCode remain replaceable host dependencies; no harness was forked.

Live validation on Community Cloud pod `d2rizci8dwgvne` (RTX A4000) found that
the pinned llama.cpp build requires a value for `--flash-attn`; the recipe also
failed to propagate a rejected server launch. The final command uses
`--flash-attn auto`, and its failure branch now exits nonzero. Subsequent
qualification evidence is recorded in `STATE.md`. The same run proved the
published v2 image omitted CUDA architecture 8.6, so RTX A4000/3090 inference
fails. The Docker default now includes 8.6, but GPU and end-to-end agent
qualification remain unproven until the corrected image is published and run.
