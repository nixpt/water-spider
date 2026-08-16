# WATERS-018 — Publish all image variants to GHCR on release

| Field | Value |
|-------|-------|
| **ID** | WATERS-018 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | Public release |
| **Assignee** | codex |
| **Dependencies** | WATERS-005, WATERS-016 |
| **Estimated effort** | S |

## Problem

water-spider images are available from Docker Hub, but releases do not publish
equivalent images to GitHub Container Registry next to the source repository.

## Success criteria

- [x] Releases publish the CLI, CPU control-pod, and GPU control-pod variants.
- [x] Each variant receives a moving tag and an immutable project-version tag.
- [x] Publication authenticates with the scoped GitHub Actions token.
- [x] OCI metadata links packages to the source repository and release.
- [x] GitHub Actions caching is isolated per image variant.
- [x] Documentation-only releases do not rebuild unchanged images.
- [x] User and release documentation explain both registries and GHCR tags.

## Resolution

Extended the release workflow with a three-entry Buildx matrix that publishes
`latest`, `pod`, and `v2` plus versioned counterparts to
`ghcr.io/nixpt/water-spider`. The workflow uses `packages: write`, the built-in
`GITHUB_TOKEN`, source/version/revision labels, and per-variant Actions caches.
