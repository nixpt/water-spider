# water-spider — State (2026-08-16)

**Role:** RunPod GPU-pod-lifecycle CLI, built on `runpodctl` + the RunPod
GraphQL API. Extracted from `jokersquad/bin/water-spider` (2026-08-16) into
its own standalone, publishable repo so the tool and its image can ship
independently of the fleet's internal `jokersquad`/`zorro` repos. Not
zorro-specific — defaults to the `nixpt/zorro` image family via env vars,
but works with any RunPod pod template.

**Runtime:** pure Bash with `runpodctl`/`ssh`/`jq`/`pgrep`; `curl` is
conditional for GraphQL-only creation flags and `bucket-bridge` can optionally
provision supported missing tools.
**Verification:** 29 deterministic command cases, Bash syntax checks, and
ShellCheck 0.10.0. See `docs/testing.md`.

**Origin:** extracted from `jokersquad/bin/water-spider` via
`foreman-scaffold --type shell`, 2026-08-16. Full history (feature
development, live-tested fixes) stays in `jokersquad`'s
`vega/water-spider` branch / squadron PR #29 — this repo starts fresh
from the finished script, not a `git subtree split`.

**Remote:** `nixpt/water-spider` (public) — https://github.com/nixpt/water-spider

**Published images (Docker Hub, `nixpt/water-spider`):**
- `:2.9.0` / `:latest` — lightweight one-shot CLI (179MB, `Dockerfile`)
- `:pod` — CPU-only RunPod "control pod" variant, persistent SSH-reachable
  container with water-spider on PATH (2.81GB, `Dockerfile.runpod`, base
  `runpod/base:1.1.0-rc.154-ubuntu2204`)
- `:v2` — GPU control pod (2026-08-16): adds real inference capability —
  llama.cpp (`ggml-org/llama.cpp` b10451, built from source with CUDA;
  no Linux CUDA prebuilt exists upstream, checked directly) + `hf` CLI for
  pulling GGUF models. Base `runpod/pytorch:1.0.3-cu1281-torch291-ubuntu2404`
  (same as `nixpt/zorro`'s own image — proven SSH self-heal). `zorro`
  itself is NOT in this image (stays private) — llama.cpp is a fully
  separate, general-purpose engine. 32.2GB, `CUDA_ARCHS="89;90;120"`
  (Ada/Hopper/Blackwell). Real bug found+fixed during the build: llama.cpp's
  CMake links `CUDA::cuda_driver` (an absolute-path `find_library` lookup,
  not a bare `-l` flag) for its VMM allocator path — no real `libcuda.so.1`
  exists at Docker BUILD time (only once a GPU is attached at `docker run`),
  so this always fails to resolve regardless of `-L` search-path flags;
  fixed via llama.cpp's own documented `-DGGML_CUDA_NO_VMM=ON` escape
  hatch rather than fighting CMake's driver detection. Second bug: an
  earlier version installed only the tool binaries and deleted `build/`,
  breaking all of them (`libllama-cli-impl.so: cannot open shared object
  file`) since llama.cpp also produces shared libs the binaries dynamically
  link — fixed by installing `*.so*` to `/usr/local/lib` + `ldconfig`
  before cleanup, in a separate `RUN` so an install-only fix doesn't force
  a full recompile. Third bug, only visible on REAL hardware (both prior
  bugs were caught locally): llama.cpp's `GGML_NATIVE` defaults ON
  upstream (`-march=native`) — baked in THIS dev box's exact CPU, so every
  binary SIGILL'd (Illegal instruction, core dumped) the instant it ran
  on a real RunPod pod with a different CPU, despite running fine in
  local `docker run` smoke tests (same machine that built it). Fixed with
  an explicit portable baseline (`GGML_NATIVE=OFF`,
  SSE4.2/AVX/AVX2/BMI2 ON, AVX512 OFF). `docker/water-spider-pod-init.sh`
  — GPU clock-lock + verify, ported from `zorro-pod-init.sh` (generic
  GPU-ops knowledge, not zorro-specific code).

**Full v2 live-test, real pod, real GPU** (2026-08-16, after the SIGILL
fix): `water-spider create` (RTX 5090) → SSH → `water-spider-pod-init` →
`hf download` (Qwen2.5-0.5B GGUF) → `llama-server -ngl 999` →
`nvidia-smi` confirmed 1384 MiB resident on GPU (not CPU fallback) →
`water-spider tunnel` → a real `/completion` request from THIS machine
through the tunnel returned a correct completion at 427 tok/s →
`water-spider teardown` → independently re-verified gone via a fresh
`water-spider list`. Cost discipline: the FIRST test pod (pre-fix, hit
the SIGILL) was torn down immediately rather than left idle while
rebuilding.

**Published RunPod Templates:**
- `water-spider-control-pod-public` (id `d5q8gekgxt`, public, CPU
  category, image `nixpt/water-spider:pod`)
- `water-spider-gpu-control-pod` (id `q1dp5mbtls`, public, NVIDIA
  category, image `nixpt/water-spider:v2`)

Both created via `docker/create-runpod-template.sh` (`TAG`/`NAME`/
`CATEGORY`/`README`/`CONTAINER_DISK_GB` env vars switch which variant;
`PUBLISH_PUBLIC=1` to publish — isPublic must be set at creation, a
platform quirk documented in the script's own header).

**RunPod registry auth** (2026-08-16): `nixpt/zorro` was flipped private on
Docker Hub (via the web UI — the API's own visibility PATCH silently
no-ops, a platform quirk, not fixable from this side). Registered Docker
Hub creds with RunPod so `water-spider create` can still pull it — live
id `cmsvny408000t1p6ujkm1o1uc` (name `nixpt-dockerhub`, created via
`docker/create-registry-auth.sh`). Live-tested end to end: created a real
pod with `--registry-auth-id` set, confirmed via SSH it pulled the
private image and `zorro --version` ran, then torn down.
`$WATER_SPIDER_REGISTRY_AUTH_ID=cmsvny408000t1p6ujkm1o1uc` makes this the
default for future `create` calls without passing the flag every time.

**Remaining validation:** live evidence covers create, SSH, registry-authenticated
pulls, GPU initialization/inference, tunneling, HTTP completion, teardown, and
independent absence verification. `send`/`receive`, the `recipe serve` wrapper,
GUI forwarding, and snapshot collection remain explicitly unproven on a live
pod (WATERS-003).

**Release state:** the canonical GitHub remote is configured; `VERSION` and
`v0.1.0` establish the project release line. The release workflow no-ops on an
already-tagged HEAD and bumps later conventional commits. Docker tag `2.9.0`
remains the bundled `runpodctl` version, not a water-spider project release.
The active fleet-default ruleset blocks deletion and force-push of `main`.
