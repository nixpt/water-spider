# Decisions


## 2026-08-16T07:19:33-05:00 — llama.cpp CUDA build: GGML_CUDA_NO_VMM + GGML_NATIVE=OFF

Reason:
Docker build environment has no real libcuda.so.1 (only injected at docker run with a GPU attached) and the build machine's CPU differs from the eventual RunPod host's CPU

Rejected alternatives:
- **-L/path/to/stubs generic linker flags for the VMM driver link**: doesn't work, CUDA::cuda_driver is an absolute-path find_library lookup, not a bare -l flag search path
- **GGML_NATIVE=ON (upstream default)**: builds fine and runs fine locally (same machine), then SIGILLs on any RunPod host with a different CPU — only caught via a real pod test, not local docker run

