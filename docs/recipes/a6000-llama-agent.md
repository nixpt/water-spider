# Recipe: RTX A6000 (48 GB) llama.cpp pod for agent data collection

Status: DRAFT, filled in as the 2026-11-19 pod session (WATERS-025) progresses.
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

RESULTS_PLACEHOLDER
