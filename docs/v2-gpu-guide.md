# v2 GPU, llama.cpp, and GUI guide

The `v2` image is a GPU-capable water-spider control pod. It can manage other
RunPod pods and run CUDA-backed llama.cpp inference on its own attached GPU.
It also contains the SSH/X11 plumbing needed to launch graphical applications
through `water-spider gui` and the node MCP server described in
[`mcp.md`](mcp.md).

Use either public registry:

```text
ghcr.io/nixpt/water-spider:v2
nixpt/water-spider:v2
```

For a reproducible deployment, replace `v2` with an immutable release tag such
as `v2-0.4.0` on GHCR. The published RunPod template is
`water-spider-gpu-control-pod` (`q1dp5mbtls`).

## Included software

- CUDA-enabled `llama-server`, `llama-cli`, `llama-bench`, `llama-quantize`,
  and `llama-gguf-split`;
- `hf` and `hf_transfer` for model downloads;
- `nvidia-smi` from the CUDA/PyTorch RunPod base image;
- `water-spider`, `runpodctl`, SSH, `xauth`, and `water-spider-mcp`;
- `/workspace/scratch/{models,builds,tmp,hf-cache}` as the conventional working
  directories.

The image does not include zorro or a catalog of desktop applications. Install
the GUI program you need on the running pod, or derive an image that adds it.

## Create and connect safely

Set a cost ceiling and teardown deadline before creating a GPU pod. Use a stable
idempotency key so a retry cannot create a second billable resource.

```sh
water-spider create \
  --template-id q1dp5mbtls \
  --gpu "NVIDIA GeForce RTX 4090" \
  --idempotency-key v2-demo-001

water-spider connect POD-ID
ssh root@POD-IP -p SSH-PORT
```

Only SSH port 22 needs a RunPod mapping. Inference, MCP, and GUI traffic travel
through the same authenticated SSH path; do not expose their ports publicly.

## Verify the GPU and image

On the pod:

```sh
cat /etc/water-spider-image.json
nvidia-smi
llama-server --version
hf --help
```

For repeatable benchmarks, run the supplied initializer once after connecting:

```sh
water-spider-pod-init
```

It attempts to enable persistence mode, locks both GPU core and memory clocks,
prints the observed clock state, and creates the scratch directories. RunPod
may deny clock control on some hosts; the script reports that instead of
claiming the lock succeeded. Release successful locks when finished:

```sh
nvidia-smi -rgc
nvidia-smi -rmc
```

Clock locking is useful for benchmark comparisons, not required for ordinary
inference.

## Download a GGUF model

Public models need no token. Authenticate with `hf auth login` or a scoped
`HF_TOKEN` only for gated or private repositories.

```sh
hf download OWNER/MODEL MODEL.Q4_K_M.gguf \
  --local-dir /workspace/scratch/models
```

| Purpose | Path/environment |
|---|---|
| GGUF models | `/workspace/scratch/models` / `WATER_SPIDER_MODELS_DIR` |
| Hugging Face cache | `/workspace/scratch/hf-cache` / `HF_HOME` |
| Build output | `/workspace/scratch/builds` |
| Temporary data | `/workspace/scratch/tmp` |

`/workspace` is persistent only when the selected RunPod storage configuration
provides that guarantee. Confirm it before treating models or results as
durable.

## Serve llama.cpp on the GPU

Start the server on pod loopback. `-ngl 999` requests that all supported model
layers be offloaded to the GPU:

```sh
llama-server \
  -m /workspace/scratch/models/MODEL.Q4_K_M.gguf \
  --host 127.0.0.1 --port 8080 -ngl 999
```

In another local terminal, create the SSH tunnel and call the server:

```sh
water-spider tunnel POD-ID --port 8080:8080
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/completion \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"Water spiders can","n_predict":32}'
```

Or let water-spider launch the server and tunnel in one command:

```sh
water-spider recipe serve POD-ID \
  /workspace/scratch/models/MODEL.Q4_K_M.gguf \
  --engine llama --port 8080
```

Confirm actual GPU use instead of assuming offload succeeded:

```sh
nvidia-smi
```

The other installed llama.cpp tools support direct inference, benchmarking,
quantization, and GGUF splitting:

```sh
llama-cli -m /workspace/scratch/models/MODEL.gguf -ngl 999 -p "Hello"
llama-bench -m /workspace/scratch/models/MODEL.gguf -ngl 999
llama-quantize INPUT-F16.gguf OUTPUT-Q4_K_M.gguf Q4_K_M
llama-gguf-split --help
```

## Run GUI applications

GUI forwarding uses SSH; it does not need a public display port. The local
machine needs an X server. Linux desktops normally provide one; macOS can use
XQuartz, and Windows can use an X server under WSL or a native X server.

The image includes `xauth`, but not arbitrary GUI applications. For example,
install a small X11 test application on the running pod:

```sh
ssh root@POD-IP -p SSH-PORT \
  'apt-get update && apt-get install -y --no-install-recommends x11-apps'
```

Then launch it locally:

```sh
water-spider gui POD-ID --x11 -- xeyes
```

Use `--trusted` only for applications you trust; it changes raw forwarding from
SSH `-X` to less-restricted `-Y`. Stock v2 guarantees the `xauth` dependency
for raw X11 but does not install an xpra server, so use `--x11`. The default
mode prefers xpra when a local client exists and is appropriate only when the
pod image also supplies xpra. The command construction is deterministically
tested, but neither GUI transport has completed WATERS-003 live validation.

For browser-based GPU applications, bind the application to pod loopback and
forward its HTTP port with `water-spider tunnel`; X11 is not involved.

## Use the in-image MCP server

Set `WATER_SPIDER_MCP_ENABLE=1` in the template to start the read-only node
profile on `127.0.0.1:8765`, then forward it locally:

```sh
water-spider tunnel POD-ID --port 8765:8765
```

Point a Streamable HTTP MCP client at `http://127.0.0.1:8765/mcp`. Its tools can
inspect node, GPU, disk, and model state; they cannot start services or execute
arbitrary commands.

## Preserve results and tear down

```sh
water-spider tunnel POD-ID --stop
water-spider teardown POD-ID --pull /workspace/results
water-spider list
```

The final list is the independent absence check. If teardown cannot prove the
pod is gone, inspect the RunPod console immediately rather than assuming billing
stopped.

## Evidence boundary

The CUDA llama.cpp path was exercised on a real RunPod RTX 5090: model download,
GPU-resident server, tunneled completion request, and verified teardown all
succeeded. Clock portability and shared-library defects were fixed from that
campaign. GUI forwarding remains deterministic-test-only until WATERS-003 is
completed; this guide does not upgrade that claim.
