# water-spider Docker images

The public Docker Hub landing page is maintained in
[`DOCKERHUB.md`](DOCKERHUB.md). Changes merged to `main` are published by the
`Docker Hub description` workflow when the `DOCKERHUB_USERNAME` and
`DOCKERHUB_PAT` repository secrets are configured. For a manual refresh, export
the same variables and run `scripts/update-dockerhub-description.sh` from the
repository root.

The same three variants are published to GitHub Container Registry when a
release changes an image input. Documentation-only releases skip the expensive
container builds. GHCR authentication uses the workflow's scoped `GITHUB_TOKEN`;
no registry password is stored in repository secrets.

```sh
docker pull ghcr.io/nixpt/water-spider:latest
docker pull ghcr.io/nixpt/water-spider:pod
docker pull ghcr.io/nixpt/water-spider:v2
```

Three separate images, three different jobs. None of them bundle `zorro`
Four separate images, four different jobs. None of them bundle `zorro`
— it's a private repo and a separate concern; these images are about
running water-spider (and, for `:v2`, llama.cpp) portably.

| Tag | Dockerfile | Base | Size | Job |
|---|---|---|---|---|
| `:latest` / `:2.9.0` | `../Dockerfile` | `debian:bookworm-slim` | 179MB | One-shot CLI: `docker run --rm nixpt/water-spider create ...` |
| `:pod` | `../Dockerfile.runpod` | `runpod/base:1.1.0-rc.154-ubuntu2204` | 2.81GB | CPU control pod — orchestrates *other* pods, no compute of its own |
| `:v2` | `../Dockerfile.v2` | `runpod/pytorch:1.0.3-cu1281-torch291-ubuntu2404` | 11.96GB rebuilt (11.41GB before; +0.55GB) | GPU control pod — llama.cpp CUDA fatbin (`75;80;86;89;90;120`) + `hf` CLI |
| `:train` | `../Dockerfile.train` | `nixpt/water-spider:v2` | 12.29GB | v2 plus pinned PyTorch/Transformers/TRL/PEFT/datasets/accelerate and FLA GDN stack |

GHCR also retains immutable project-version tags: `:<version>`,
`:pod-<version>`, and `:v2-<version>`. For example, release `0.4.0` publishes
`:0.4.0`, `:pod-0.4.0`, and `:v2-0.4.0` alongside the moving tags above.

All variants include `water-spider-mcp`. The one-shot `:latest` image can run
it by overriding the entrypoint; the control images can serve the safe node
profile on pod loopback when `WATER_SPIDER_MCP_ENABLE=1`. See
[`../docs/mcp.md`](../docs/mcp.md) for client configuration and SSH tunneling.
The complete operator walkthrough for v2 is
[`../docs/v2-gpu-guide.md`](../docs/v2-gpu-guide.md); it covers CUDA setup,
models, every installed llama.cpp tool, inference tunnels, GUI forwarding,
storage, MCP, and safe teardown.

```sh
docker run --rm -i --entrypoint water-spider-mcp \
  -v "$HOME/.runpod:/root/.runpod:ro" \
  nixpt/water-spider --profile control --transport stdio
```

## Build

```sh
# lightweight CLI
docker build -t nixpt/water-spider .

# CPU control pod
docker build -f Dockerfile.runpod -t nixpt/water-spider:pod .

# GPU control pod (fatbin covers T4/Turing through Blackwell — sm_75 for
# free Colab/Kaggle T4s, sm_80 for A100 pods; narrow for faster builds)
docker build -f Dockerfile.v2 -t nixpt/water-spider:v2 \
  --build-arg CUDA_ARCHS="75;80;86;89;90;120" .

# Training / fine-tuning variant (build v2 first)
docker build -f Dockerfile.train -t nixpt/water-spider:train .
```

## Why `:v2` exists separately from `:pod`

`:pod`'s whole point is staying tiny — it just manages other pods over
SSH. Bolting CUDA + llama.cpp onto it would triple its size for a
capability most `:pod` deployments never use. `:v2` is the answer for
"I want ONE pod that both orchestrates and runs inference" instead of
the two-pod dance (a `:pod` control pod pointing at a separate zorro/
llama.cpp pod).

## Scripts in this directory

- **`create-registry-auth.sh`** — registers Docker Hub credentials with
  RunPod (`containerregistryauth` REST endpoint) so `water-spider create`
  can pull a **private** image. Needed the moment any `nixpt/*` image
  goes private (as `nixpt/zorro` did 2026-08-16) — `runpodctl`'s own CLI
  has no flag for this at all. See `bin/water-spider`'s
  `--registry-auth-id` / `$WATER_SPIDER_REGISTRY_AUTH_ID`.
- **`create-runpod-template.sh`** — publishes a RunPod Template via the
  REST v1 API (GraphQL introspection is disabled server-side, so REST is
  the only way to verify the shape before use). `TAG`/`NAME`/`CATEGORY`/
  `README`/`CONTAINER_DISK_GB`/`PORTS` env vars pick which image variant
  it publishes — see the two live examples below. `PUBLISH_PUBLIC=1` sets
  `isPublic: true`, which **must** happen at creation — a RunPod platform
  bug makes any PATCH to a public template fail (`"public templates
  cannot have Registry Credentials"`, even for unrelated fields, even
  though the template's own `containerRegistryAuthId` reads back empty
  the whole time). Republishing means delete + recreate, not update.
- **`post_start.sh`** — SSH self-heal, installed as `/post_start.sh` and
  picked up automatically by the RunPod base's own `execute_script`
  hook. Ported from `nixpt/zorro`'s own `docker/post_start.sh` — the
  logic (re-derive `setup_ssh()`, verify sshd is actually LISTENING
  rather than trusting `service ssh start`'s exit code) is generic to
  any `runpod/base`-family image, not zorro-specific.
- **`water-spider-pod-init.sh`** — installed as `water-spider-pod-init`
  on `:v2` only. GPU clock-lock + verify (reproducible-benchmark
  discipline), ported from `nixpt/zorro`'s `zorro-pod-init.sh` — again,
  generic GPU-ops knowledge, not zorro source.

## RunPod templates (LIVE)

| Template | id | Category | Image | Public |
|---|---|---|---|---|
| `water-spider-control-pod-public` | `d5q8gekgxt` | CPU | `nixpt/water-spider:pod` | yes |
| `water-spider-gpu-control-pod` | `q1dp5mbtls` | NVIDIA | `nixpt/water-spider:v2` | yes |

Both created via `create-runpod-template.sh`:

```sh
# CPU pod (already published — for reference)
PUBLISH_PUBLIC=1 bash docker/create-runpod-template.sh

# GPU pod (already published — for reference)
TAG=v2 NAME=water-spider-gpu-control-pod CATEGORY=NVIDIA \
CONTAINER_DISK_GB=60 PUBLISH_PUBLIC=1 \
  bash docker/create-runpod-template.sh
```

## GPU pod use (`:v2`)

This is only the shortest smoke path. Use the
[full v2 guide](../docs/v2-gpu-guide.md) for prerequisites and operational
details.

```sh
ssh root@<pod-ip> -p <port>
water-spider-pod-init                            # lock+verify GPU clocks
hf download <repo> <file.gguf> --local-dir /workspace/scratch/models
llama-server -m /workspace/scratch/models/<file.gguf> --port 8080 -ngl 999
```

From your own machine, `water-spider tunnel <pod-id> --port LOCAL:8080`
forwards it, then `curl localhost:LOCAL/completion ...` reaches the
pod's GPU directly.

## Verified at authoring time (2026-08-16)

**`:pod` (CPU control pod):** live-tested — created a real pod, confirmed
SSH self-heal, `water-spider` on `PATH`, teardown, independently
re-verified gone.

**`:v2` (GPU control pod):** three real bugs found via live testing, not
caught by any local check — fixed and re-verified, not just patched and
assumed:

1. `ggml-cuda`'s VMM allocator links `CUDA::cuda_driver` via CMake's
   `find_package(CUDAToolkit)` — an absolute-path `find_library` lookup.
   No real `libcuda.so.1` exists at Docker **build** time (only injected
   once a GPU is attached at `docker run`), so this always fails to
   resolve regardless of linker `-L` search-path flags. Fixed via
   llama.cpp's own documented `-DGGML_CUDA_NO_VMM=ON`.
2. An earlier version installed only the tool binaries and deleted
   `build/` — but llama.cpp also produces shared libraries the binaries
   dynamically link against, living in that same directory. Broke every
   binary (`libllama-cli-impl.so: cannot open shared object file`).
   Fixed by installing `*.so*` to `/usr/local/lib` + `ldconfig` first.
3. **SIGILL on real RunPod hardware.** `GGML_NATIVE` defaults `ON`
   upstream (`-march=native`) — bakes in the exact CPU of whatever
   machine runs the Docker build. Ran fine in every local `docker run`
   smoke test (same machine that built it) and then crashed instantly
   (`Illegal instruction, core dumped`) the moment it ran on a real
   RunPod pod with a different host CPU. Only caught via a live pod
   test — fixed with an explicit portable baseline (`GGML_NATIVE=OFF`,
   SSE4.2/AVX/AVX2/BMI2 `ON`, AVX512 `OFF`).

Full loop re-verified on the fixed image, real pod, real GPU:
`water-spider create` (RTX 5090) → SSH → `water-spider-pod-init` →
`hf download` (Qwen2.5-0.5B GGUF) → `llama-server -ngl 999` →
`nvidia-smi` confirmed 1384 MiB resident on GPU (not CPU fallback) →
`water-spider tunnel` → a real `/completion` request from the local
machine through the tunnel returned a correct completion at 427 tok/s →
`water-spider teardown` → independently re-verified gone via a fresh
`water-spider list`. The pre-fix pod that hit the SIGILL was torn down
immediately rather than left idle while rebuilding.
