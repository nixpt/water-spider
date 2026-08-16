# water-spider — State (2026-08-16)

**Role:** RunPod GPU-pod-lifecycle CLI, built on `runpodctl` + the RunPod
GraphQL API. Extracted from `jokersquad/bin/water-spider` (2026-08-16) into
its own standalone, publishable repo so the tool and its image can ship
independently of the fleet's internal `jokersquad`/`zorro` repos. Not
zorro-specific — defaults to the `nixpt/zorro` image family via env vars,
but works with any RunPod pod template.

**Deps:** none (Rust-free — pure bash, `runpodctl`/`ssh`/`jq`/`pgrep` at
runtime, `bucket-bridge` optional for JIT-provisioning a missing dep)
**Build:** `shellcheck bin/water-spider`.

**Origin:** extracted from `jokersquad/bin/water-spider` via
`foreman-scaffold --type shell`, 2026-08-16. Full history (feature
development, live-tested fixes) stays in `jokersquad`'s
`vega/water-spider` branch / squadron PR #29 — this repo starts fresh
from the finished script, not a `git subtree split`.

**Remote:** `nixpt/water-spider` (public, once pushed).
