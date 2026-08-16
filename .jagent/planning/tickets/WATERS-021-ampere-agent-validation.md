# WATERS-021 — Publish and validate Ampere agent inference

| Field | Value |
|-------|-------|
| **ID** | WATERS-021 |
| **Priority** | P1 |
| **Status** | Ready |
| **Phase** | Agent runtime |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-020 |
| **Estimated effort** | M |

## Problem

WATERS-020 live validation proved that the published v2 image lacks CUDA
architecture 8.6 and cannot run llama.cpp on RTX A4000/3090 GPUs. The source
default is corrected, but an image containing that correction has not been
published or qualified.

## Success criteria

- [ ] Publish a v2 image whose provenance reports CUDA architecture 8.6.
- [ ] Start llama.cpp on a capped Community RTX A4000/3090 and confirm GPU
  residency with `nvidia-smi`.
- [ ] Complete the Mayfly/OpenCode constrained-edit qualification.
- [ ] Tear down and independently verify absence.
- [ ] Replace failure caveats with exact release and sanitized evidence.

## Evidence

Community pod `d2rizci8dwgvne` cost $0.17/hour and was used from approximately
13:04–13:18 CDT on 2026-08-16. The published binary failed with `no kernel
image is available for execution on the device`; the pod was then confirmed
deleted while foreman pod `f2xau4gu5fhwtj` remained untouched.
