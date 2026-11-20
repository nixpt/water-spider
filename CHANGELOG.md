# Changelog

All notable changes to water-spider are recorded here. The format loosely
follows [Keep a Changelog](https://keepachangelog.com/); released versions must
match `v*` Git tags. Once the initial tag exists, `scripts/bump-version.sh`
appends entries mechanically on pushes to `main`.

## [Unreleased]

## [0.8.0] - 2026-11-20

- Merge pull request #14 from nixpt/agent/ann/WATERS-028-pod-top-logs-watch
- fix: address usagi review on #14 (logs allowlist + remote realpath, tail --pid, padded df JSON, --out perms, dedicated follow connection) (WATERS-028)
- feat: pod visibility top + logs + watch --json (WATERS-028)
- wip: top/watch (WATERS-028)



## [0.7.0] - 2026-11-20

- Merge pull request #13 from nixpt/agent/ann/WATERS-027-pod-ps-gpu
- fix: ps survives SIGPIPE when head closes early on large process tables (WATERS-027)
- fix: address usagi review (redaction gaps+idempotency, fail-closed ControlMaster dir, remote timeouts, id/port validation) (WATERS-027)
- fix: gpu view also computes listener risk flags (WATERS-027)
- style: shellcheck clean (WATERS-027)
- feat: pod visibility ps + gpu, read-only over one ssh round trip (WATERS-027)



## [0.6.6] - 2026-11-20

- Merge pull request #12 from nixpt/agent/ann/WATERS-025-a6000-recipe
- docs: A6000 recipe, quantizing section (WATERS-025)
- docs: A6000 recipe M2/M3 results, live-traffic stats, raw rows (WATERS-025)
- docs: A6000 recipe M1/M2 results, MTP findings and pod gotchas (WATERS-025)
- tunnel: add ServerAliveInterval/CountMax so a stalled forward dies instead of hanging (WATERS-025)
- docs: A6000 llama-agent recipe draft (WATERS-025)



## [0.6.5] - 2026-11-19

- Merge pull request #10 from nixpt/agent/ann/WATERS-024
- fix: pass RunPod API key to curl via stdin config, not argv (WATERS-024)
- fix: move pod list/get/terminate/verify to GraphQL; rest.runpod.io is gone (WATERS-024)



## [0.6.4] - 2026-08-30

- file WATERS-022: bake wsforge-style agent confinement into the pod images (#6)



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
