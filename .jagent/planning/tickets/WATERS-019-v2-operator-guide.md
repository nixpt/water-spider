# WATERS-019 — Document the v2 operator workflow

| Field | Value |
|-------|-------|
| **ID** | WATERS-019 |
| **Priority** | P2 |
| **Status** | Done |
| **Phase** | Documentation |
| **Assignee** | codex |
| **Dependencies** | WATERS-009, WATERS-016, WATERS-018 |
| **Estimated effort** | M |

## Problem

The v2 image contains CUDA llama.cpp, Hugging Face tooling, GPU initialization,
X11 support, and the node MCP binary, but existing documentation provides only
a terse inference snippet and build-incident history rather than a usable
operator workflow.

## Success criteria

- [x] Document image selection, the public template, and cost-safe creation.
- [x] Inventory installed GPU, model, llama.cpp, X11, and MCP capabilities.
- [x] Explain GPU initialization, verification, clock reset, and limitations.
- [x] Cover model storage, downloads, inference, tunnels, and GPU confirmation.
- [x] Cover GUI client/pod prerequisites and the xpra/raw-X11 boundary.
- [x] Cover artifacts, teardown, and the live-evidence boundary.
- [x] Link the guide from user, CLI, Docker, and registry documentation.
- [x] Prevent the documentation release from rebuilding unchanged GPU images.

## Resolution

Added a dedicated v2 operator guide spanning deployment through verified
teardown. Updated repository navigation, getting started, CLI guidance, the
Docker reference, and Docker Hub copy so the image's runtime capabilities and
limitations are discoverable without reading its Dockerfile. Added release
path detection so this documentation-only release does not start another large
CUDA image build.
