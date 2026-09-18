# WATERS-023 — `snapshot` carries the pod's scripts, serve env/argv and runtime; `restore-scripts` replays them

| Field | Value |
|-------|-------|
| **ID** | WATERS-023 |
| **Priority** | P1 |
| **Status** | Done (this PR) |
| **Phase** | Release Readiness |
| **Assignee** | foreman (s459) |
| **Dependencies** | none |
| **Estimated effort** | S |

## Why

Both provider pods this month (A100 `guqnym8bcn1uf4`, RTX 6000 Ada `lmxnpetd9dzzgs`) were built by
hand-written `/root/{setup,pull,serve}.sh` plus env knobs discovered the hard way
(`VLLM_USE_FLASHINFER_SAMPLER=0`, cuda-12.4 on PATH, `--tool-call-parser qwen3_xml`). `snapshot`
recorded only a model-file list + zorro image provenance, so tearing a pod down lost the recipe;
the captain asked for the configs/envs/scripts to be snapshotted for reproducibility.

## What landed

- `snapshot <pod> [-o FILE] [--scripts GLOB]` now adds to the manifest: `scripts` (path → contents
  of `/root/*.sh` + `/workspace/*.sh` by default), `serve.argv` (the live vllm/llama-server/zorro/pf
  process), `serve.env` (its `/proc/<pid>/environ`, filtered to the build/runtime prefixes, any var
  named `*TOKEN*|*KEY*|*SECRET*|*PASSWORD*` masked), `runtime.{gpu,os,pip_freeze}`, `taken_at`.
  The remote side no longer needs `jq` (the RunPod pytorch image has none — the first live run
  came back empty for exactly that reason); all shaping is local.
- `restore-scripts <pod> <snapshot.json>` writes the carried scripts back at their original paths
  (`chmod +x`), does **not** run them (setup → pull → serve order and the token over stdin are
  the operator's steps). `create --restore` prints the command when the manifest carries scripts.
- Tests: 5 new cases on the ssh fake (scripts + serve + runtime present, secrets masked, argv/gpu,
  restore writes, create --restore lists). Live-verified against `lmxnpetd9dzzgs`: 3 scripts,
  4 env lines (HF_TOKEN masked), 299 packages, 1 model.

## Not done / follow-ups

- The manifest still doesn't know which HF repo a model dir came from — `pull.sh` does, so a
  carried `pull.sh` is the de-facto answer; a `model_sources` field parsed from `hf download`
  lines is the next step.
- `recipe serve --engine vllm` (the hand-rolled serve.sh as a first-class recipe) — separate ticket.
