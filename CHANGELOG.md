# Changelog

All notable changes to water-spider are recorded here. The format loosely
follows [Keep a Changelog](https://keepachangelog.com/); released versions must
match `v*` Git tags. Once the initial tag exists, `scripts/bump-version.sh`
appends entries mechanically on pushes to `main`.

## [Unreleased]

## [0.6.3] - 2026-08-22

- security: re-remove leaked dev config reintroduced by PR #3's rebase (#5)



## [0.6.2] - 2026-08-22

- scripts: make docker/create-registry-auth.sh idempotent and more robust (#3)



## [0.6.1] - 2026-08-22

- security: remove leaked local dev config, harden .gitignore (#4)



## [0.6.0] - 2026-08-17

- feat: multi-arch CUDA v2 and training image (#2)



## [0.5.0] - 2026-08-16

- Merge pull request #1 from nixpt/ticket/waters-020-mayfly-opencode
- fix: add Ampere llama agent support
- feat: integrate mayfly opencode agents



- feat: connect Mayfly and OpenCode to tunneled v2 llama.cpp inference
- fix: compile v2 for Ampere GPUs and propagate failed agent-server launches

## [0.4.1] - 2026-08-16

- docs: add v2 GPU operator guide



## [0.4.0] - 2026-08-16

- feat: publish release images to GHCR



## [0.3.0] - 2026-08-16

- feat: add read-only MCP server



## [0.2.0] - 2026-08-16

- feat: add water-spider agent skill



## [0.1.5] - 2026-08-16

- docs: add CLI and user guides



## [0.1.4] - 2026-08-16

- test: follow current release version



## [0.1.3] - 2026-08-16

- docs: publish Docker Hub overview



## [0.1.2] - 2026-08-16

- docs: add water-spider brand assets



## [0.1.1] - 2026-08-16

- fix: use ShellCheck release tag in CI



## [0.1.0] - 2026-08-16

- Initial standalone RunPod lifecycle CLI.
- Cost-safe creation, idempotency, verified teardown, tunnels, recipes, GUI
  forwarding, and lightweight snapshots.
- Deterministic 29-case command suite and hardened GraphQL creation path.
- Standalone, CPU-control-pod, and CUDA/llama.cpp GPU image variants.
- Dual MIT/Apache-2.0 licensing and public contribution documentation.

Docker image tag `2.9.0` identifies the bundled `runpodctl` release and is
separate from water-spider's project version.
