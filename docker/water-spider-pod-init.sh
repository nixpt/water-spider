#!/usr/bin/env bash
# water-spider-pod-init — run ONCE on a fresh GPU pod before benchmarking.
#
# Deliberately NOT a container entrypoint: overriding the pod command stops
# RunPod starting its own ssh service, which leaves declared ports with
# nothing behind them. Run this after you ssh in.
#
# The clock-locking logic here is generic GPU-ops knowledge (reproducible-
# benchmark discipline), not zorro-specific — ported from nixpt/zorro's own
# docker/zorro-pod-init.sh, which documents the same pattern for zorro's
# own CUDA kernels. Nothing zorro-proprietary is in this file.
set -u
echo "== image provenance =="; cat /etc/water-spider-image.json 2>/dev/null

echo "== locking clocks (BOTH: -lgc alone is insufficient) =="
# Single-stream decode is memory-BANDWIDTH bound, so clocks.mem dominates
# clocks.sm. Separate invocations: the driver refuses both in one call.
nvidia-smi -pm 1 >/dev/null 2>&1 || echo "  (persistence: no permission)"
MAXSM=$(nvidia-smi --query-gpu=clocks.max.sm  --format=csv,noheader,nounits | head -1)
MAXMEM=$(nvidia-smi --query-gpu=clocks.max.mem --format=csv,noheader,nounits | head -1)
FLOOR=$(( MAXSM * 78 / 100 ))   # ~78% of max ≈ sustained ceiling, not boost-max
nvidia-smi -lgc "${FLOOR},${MAXSM}" >/dev/null 2>&1 || echo "  (lgc: no permission)"
nvidia-smi -lmc "${MAXMEM}"        >/dev/null 2>&1 || echo "  (lmc: no permission)"

echo "== VERIFY (never assume a lock took — one silently lapsed before) =="
nvidia-smi --query-gpu=name,clocks.sm,clocks.mem,persistence_mode --format=csv

mkdir -p /workspace/scratch/{models,builds,tmp,hf-cache}
cat <<'NOTE'

== benchmarking protocol (this stack can produce STABLE WRONG numbers) ==
  1. clocks locked + VERIFIED above (both sm and mem)
  2. PAIR the A/B: interleave arms, pair temporally adjacent samples, report
     the stdev of the RATIOS -- even fully locked, both arms drift together
  3. quote the machine state beside every tok/s figure
  release locks when done:  nvidia-smi -rgc -rmc

== llama.cpp quick start ==
  hf download <repo> <file.gguf> --local-dir /workspace/scratch/models
  llama-server -m /workspace/scratch/models/<file.gguf> --port 8080 -ngl 999
NOTE
