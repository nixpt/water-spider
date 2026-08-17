# Colab free-GPU path

This is the low-cost companion path for `nixpt/water-spider`. A free Colab
T4 is an NVIDIA `sm_75` GPU with 16 GB VRAM. The v2 image includes `sm_75` in
its llama.cpp fatbin, so a RunPod T4 can use the published `:v2` image without
rebuilding llama.cpp. Colab-hosted notebooks normally do not provide Docker
or a persistent privileged runtime, so use the pip bootstrap below there.

## What the T4 is good for

The practical envelope is cells-scale experiments, small LoRA/SFT jobs, and
llama.cpp inference with quantized models up to about 8B (context length and
KV cache reduce that ceiling). Keep the model and cache under `/content` or a
mounted Drive, watch `nvidia-smi`, and treat the runtime as disposable. A
16-bit 8B model does not fit comfortably; use a small GGUF or a 4-bit adapter
run. This is not a claim that Colab provides a stable service endpoint.

## Exact pip bootstrap cell (no Docker)

Run this in a fresh GPU runtime. Do not replace Colab's working PyTorch wheel
unless a notebook specifically needs a different CUDA build.

```python
!nvidia-smi
!python -m pip install -q --upgrade \
  "huggingface_hub[cli]==1.27.0" hf_transfer \
  "transformers==5.14.1" "trl==1.10.0" "peft==0.20.0" \
  "datasets==5.0.1" "accelerate==1.14.0" \
  "flash-linear-attention[cuda]==0.5.1" "causal-conv1d==1.6.2.post1"
```

For a Python training smoke and an explicit GDN fast-path check:

```python
import inspect, torch, fla, causal_conv1d
from transformers.models.qwen3_5 import modeling_qwen3_5
print(torch.__version__, torch.version.cuda)
print(fla.__version__, causal_conv1d.__version__)
gdn = inspect.getsource(modeling_qwen3_5.Qwen3_5GatedDeltaNet)
assert "chunk_gated_delta_rule" in gdn or "fused_recurrent" in gdn
print("fla fast path: ACTIVE (Qwen3.5 GDN fused implementation present)")
```

For a model download, use the same cache convention as the image:

```python
import os
os.environ["HF_HOME"] = "/content/hf-cache"
os.environ["HF_HUB_ENABLE_HF_TRANSFER"] = "1"
!hf download <owner>/<repo> <file.gguf> --local-dir /content/models
```

The image's `llama-server` binary is not available in a normal Colab VM. Use
a Colab-compatible llama.cpp package or build the upstream project in the
notebook, passing `CMAKE_CUDA_ARCHITECTURES=75`; do not copy a binary built
only for `sm_120`. If Docker is available in a separately provisioned Colab
runtime, `docker run --gpus all nixpt/water-spider:v2` is the image path, but
ordinary free Colab sessions should be assumed not to support it.

## Evidence and boundaries

The existing Colab record contains `/workspace/scratch/zorro-colab-artifacts/`
artifact `zorro-cuda-mmq-sm75-colab-t4` (47,349,168 bytes,
SHA-256 `c2431922cd651a173d36804ea6d50c0085b6d6a05c9bc7ebe4e7d5644f63cba7`)
and the reproducible scripts in `zorro/scripts/colab/`; that is evidence that
an sm_75 CUDA build was produced, not evidence for this water-spider image.
The requested historical `zorro/tools/zazen-colab` directory was not present
on this box. Foreman’s inbox records also document that automated browser/MCP
execution and reverse-SSH tunneling were rejected by Colab’s interactive-use
controls. Use the notebook UI manually and do not build a harness or attempt
to bypass those controls.
