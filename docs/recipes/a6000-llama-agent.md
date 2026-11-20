# Recipe: RTX A6000 (48 GB) llama.cpp pod for agent data collection

Status: results from the 2026-11-19 pod session (WATERS-025), pod torn down.
Raw rows: `docs/recipes/a6000-data/q38-gapA.jsonl`.
Pod: `bro-a6000-20261119-ann-r3` (RunPod SECURE cloud, 1x RTX A6000 49140 MiB,
driver 595.112.07, CUDA 12.4 image, ~$0.704/hr all-in with 100 GB container disk).

## Pod limits (read these first)

`nvidia-smi`, `nproc` and `free` show the HOST (96 vCPU, 503 GB). The pod is a
cgroup slice: `cpu.max` = 765000/100000 (7.65 CPUs), `memory.max` = 50 GB.
So: use `-t 8 -tb 8`, keep any `--n-cpu-moe` / CPU-side KV within 50 GB, and
never run `cmake -j32` (the llama.cpp CUDA build took ~15 min even so).
Disk: 100 GB container overlay (not a network volume); weights of 29+36+25 GB
do not all fit beside a build and a second agent's target dir, so swap models
by deleting a finished GGUF and re-pulling the next (xet pull: 25-36 GB in
1-2 minutes on this pod). Do NOT use `--slot-save-path` on the overlay.

## Setup that worked

1. Create (GraphQL path; community A6000 had no stock, SECURE did):
   `water-spider create --name <n> --idempotency-key <k> --image runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04 --gpu "NVIDIA RTX A6000" --ports 22/tcp --disk 100 --volume 0 --cloud SECURE --min-download 1`
   (`--min-download 1` only forces the GraphQL path; runpodctl 2.1.9 `pod create` hits the dead REST host.)
2. `pip install --break-system-packages "huggingface_hub[cli]" cmake ninja`; then
   `git clone --depth 1 ggml-org/llama.cpp`; `cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=86 -DLLAMA_CURL=OFF`;
   build `llama-server llama-bench llama-cli` with `-j8`.
3. Weights via `runpod-hf-pull.sh` under `runpod-secure-exec.sh` (HF token over stdin, never on disk).
4. Serve with `llama-server` directly (the built-in `recipe serve --engine llama-agent` has no `-c/-np/-ctk/-t` flags and uses alias `speedy`).
5. `pod-tunnel up <label> --host <ip> --pod-port <ssh-port> --port 18080:8080`.

## Models and why

| alias | file | size | why |
|---|---|---|---|
| qwen38-27b-q8 | unsloth/Qwen3.8-27B-GGUF Qwen3.8-27B-Q8_0 | 29 GB | the requested dense model; GDN hybrid, small KV, Q8 fits with 262k ctx |
| qwen36-35b-a3b | unsloth/Qwen3.6-35B-A3B-GGUF Qwen3.6-35B-A3B-Q8_0 | 36 GB | MoE (3B active): fast decode, still fits fully in VRAM |
| gemma4-31b | unsloth/gemma-4-31B-it-GGUF gemma-4-31B-it-Q6_K | 25 GB | gemma-4 has no 27B; 31B dense is the closest dense class; Q6_K leaves KV room |

## Results

Prompt token counts are actual `prompt_n`: short = 641, "50k" = 49,837, "100k" = 99,596.
`pp` = prefill tok/s, `tg` = decode tok/s, one request at a time unless noted. All rows: `-ngl 999 --jinja -fa on -t 8 -tb 8`.

### qwen38-27b-q8 (Qwen3.8-27B Q8_0, 29 GB, GDN hybrid)

| config | VRAM MiB | short pp/tg | 50k pp/tg | 100k pp/tg | code tg | 2 concurrent, agg tg |
|---|---|---|---|---|---|---|
| np1 -c 262144 q8_0 KV | 36550 | 1092 / 22.97 | 1281 / 19.82 | 1030 / 17.34 | 22.9 | (serialised) |
| np2 -c 262144 q8_0 KV (served to tenzo, mtp off) | 36572 | 1085 / 22.85 | 1254 / 19.79 | 1019 / 17.34 | 22.9 | 42.6 |
| np2 -c 262144 q8_0 KV + MTP n-max 3 | 39174 | 1070 / 52.1 | 1200 / 35.05 | 968 / 33.94 | 53.1 | 88.9 |
| np2 -c 131072 f16 KV | 35008 | 1101 / 23.0 | 1268 / 20.6 | does not fit (65k/slot) | 22.9 | 42.8 |
| np2 -c 262144 q8_0 KV -b 4096 -ub 1024 | 36808 | 1267 / 22.8 | 1315 / 19.7 | 1083 / 17.3 | 22.9 | 42.8 |

Findings:
- The Q8_0 GGUF ships the MTP head (`blk.64.nextn.*`); `--spec-type draft-mtp --spec-draft-n-max 3` works on the same file.
  Acceptance 63-71% (173/245 on a code prompt, mean accepted length ~3.0). Decode is 2.3x faster on short context and
  1.8-2.0x at 50-100k, for +2.6 GB VRAM and ~4% less prefill. Use it for agent runs.
- q8_0 KV costs no speed against f16 and halves KV memory; the hybrid model's KV is small anyway, so 262144 ctx fits with 12 GB spare.
- `-b 4096 -ub 1024` raises prefill 5-17% at +0.2 GB.
- The served M1 ran WITHOUT MTP and with default `-b/-ub`; mtp=off is recorded in the pilot EVENTS.log.
- Live agent traffic (tenzo's sessions, 2 slots busy): prefill 860-1350 tok/s, decode 15-20 tok/s per slot.

Winning flags: `-c 262144 -np 2 -ctk q8_0 -ctv q8_0 -fa on -t 8 -tb 8 -b 4096 -ub 1024 --spec-type draft-mtp --spec-draft-n-max 3 --jinja`.

### qwen36-35b-a3b (Qwen3.6-35B-A3B Q8_0, 37.8 GB, MoE)

Use `unsloth/Qwen3.6-35B-A3B-MTP-GGUF`: the plain unsloth Q8_0 has no MTP layers and llama-server refuses
`draft-mtp` on it ("context type MTP requested but model doesn't contain MTP layers").
Served with the winning M1 flags: VRAM 40,818 MiB at 262144 ctx / 2 slots (131072 per slot);
smoke decode 170.7 tok/s with 77% MTP acceptance (178/230, code prompt).

### gemma4-31b (gemma-4-31B-it Q6_K, 25 GB)

No `nextn`/MTP tensors in the GGUF header, so mtp=off. Served with the same flags minus MTP: `-c 262144 -np 2 -ctk q8_0 -ctv q8_0 -b 4096 -ub 1024`,
VRAM 39.5 GB. Smoke: decode 24.2 tok/s (code prompt); a 62,297-token prompt prefilled at only 215 tok/s (decode 14.8 tok/s).
Long-context prefill on gemma is ~5x slower than on Qwen3.8 (SWA/global attention at 31B dense), so budget slow first turns.

### Live agent traffic (tenzo's pilot, 2 slots busy, medians over the full server logs)

| model | generations | prefill, prompts >= 2k tok | decode median / p10 | MTP acceptance |
|---|---|---|---|---|
| qwen38-27b-q8 (mtp off) | 242 | 1326 tok/s | 19.3 / 17.3 | n/a |
| qwen36-35b-a3b (mtp on) | 482 | 3797 tok/s | 106.5 / 81.2 | 0.70 |
| gemma4-31b (mtp off) | 132 | 464 tok/s | 17.5 / 11.3 | n/a |

Rule of thumb from this card: the MoE with MTP is ~5x the decode of either dense model and ~3x the prefill; if throughput
matters more than the specific model, run `qwen36-35b-a3b` with MTP.

## Gotchas hit on this pod

- Port 8081 on the pod is RunPod's nginx: a health check passes and every POST returns `405 Not Allowed`. Serve on 8080/8090.
- `water-spider create` without a GraphQL-only flag falls back to runpodctl 2.1.9, which refuses; `--min-download 1` is a harmless way to force GraphQL.
- Community A6000 had "no longer any instances"; SECURE worked at $0.704/hr.
- `pod-tunnel`/`water-spider tunnel` used no ServerAlive options; a stalled forward hung without dying (fixed on this branch).
- Bench prompts of random `wordNNN` tokens tokenise at ~3.1 tokens per word; calibrate with `timings.prompt_n`.
- The host's `nvidia-smi`, `/proc` and `free` show 96 vCPU / 503 GB; the cgroup gives 7.65 CPUs / 50 GB.

## Quantizing on the pod (bro-aware Qwen3.6-35B-A3B, same session)

Source: the MTP repo's Q8_0 (the plain repo's Q8 has no MTP layers). Steps and exact commands are in
`/workspace/data/qwen36-35b-a3b-bro/NOTE.md` (zorro). Pod-side lessons:
- `llama-imatrix ... --chunks 90 --no-ppl`: 90 x 4096 tokens of bro traces took 11 min on the A6000 (without `--no-ppl` it was ~20% slower and printed per-chunk PPL).
- The pod's 7.65-CPU cgroup, not the GPU, sets quantization time. `IQ3_XXS` with an imatrix ran at ~1.5 min per layer (~60 min total); `Q3_K_S` took 4.3 min for the same 37.8 GB source, `Q4_K_M` ~15 min under contention. Use K-quants when time-boxed.
- Keep the MTP block: `--tensor-type "blk\.40\.(attn_.*|ffn_.*|nextn\.eh_proj)\.weight=q8_0"` keeps `blk.40.nextn.*`; without an imatrix entry for that block an IQ type would otherwise fail or degrade it.
- Quants with MTP on the A6000: Q3_K_S 205.8 tok/s (acceptance 74%), Q4_K_M 204.5 tok/s (79%), against 22.9 tok/s for the dense 27B without MTP.
- `hf upload` to a private repo fails with "Private storage limit reached" once the account quota is hit; the first 16 GB went through, the second 22 GB did not.
- `pkill -f <pattern>` from a shell whose own command line contains the pattern kills that shell; use `ps | grep "[p]attern" | awk | xargs kill`.
