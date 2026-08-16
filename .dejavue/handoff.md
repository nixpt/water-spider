# Handoff

Updated: 2026-08-16T10:50:27-05:00

## Summary
Mayfly and OpenCode are integrated as local, replaceable dependencies over the v2 image's tunneled llama.cpp tool endpoint. The wrapper, provider configuration, qualification fixture, and deterministic checks live under `integrations/mayfly-opencode/`.

## Next Steps
Publish the corrected v2 image with CUDA architecture 8.6, then rerun the WATERS-020 GPU and `qualify` checks on a capped RTX A4000/3090 pod. Complete WATERS-003 only with an authorized capped pod; keep docs/operations.md and STATE.md aligned with new live evidence.

## Boot Instructions
Read `.dejavue/handoff.md`, `.dejavue/state.md`, `.dejavue/decisions.md`, and `.dejavue/timeline.jsonl` before making changes.
