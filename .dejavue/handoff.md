# Handoff

Updated: 2026-08-16T10:50:27-05:00

## Summary
Mayfly and OpenCode are integrated as local, replaceable dependencies over the v2 image's tunneled llama.cpp tool endpoint. The wrapper, provider configuration, qualification fixture, and deterministic checks live under `integrations/mayfly-opencode/`.

## Next Steps
Run the WATERS-020 `qualify` command only when a capped v2 pod and tool-capable model are already authorized; complete WATERS-003 only with an authorized capped pod; keep docs/operations.md and STATE.md aligned with new live evidence.

## Boot Instructions
Read `.dejavue/handoff.md`, `.dejavue/state.md`, `.dejavue/decisions.md`, and `.dejavue/timeline.jsonl` before making changes.
