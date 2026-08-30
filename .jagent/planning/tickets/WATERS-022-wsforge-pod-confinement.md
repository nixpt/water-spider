# WATERS-022 — Bake wsforge-style agent confinement into the pod images

| Field | Value |
|-------|-------|
| **ID** | WATERS-022 |
| **Priority** | P1 |
| **Status** | Backlog |
| **Phase** | Release Readiness |
| **Assignee** | unassigned |
| **Dependencies** | none |
| **Estimated effort** | L |

## Problem

Every current Dockerfile (`Dockerfile`, `Dockerfile.runpod`, `Dockerfile.v2`, `Dockerfile.train`)
runs flat as root — no `USER` directive anywhere, no tier separation. A coding agent SSHed into
a pod today has full root over the whole box. That's the exact pre-wsforge gap on nixps
(uid/DAC + bwrap confinement closed it there), except a water-spider pod has real money and
irreplaceable artifacts attached: the RunPod API token, HF token, SSH keys, and trained
checkpoints. A misbehaving or hijacked agent here can burn GPU-hours, spin up more pods on the
account's bill, or corrupt a training run's checkpoints — a stronger argument for confinement
than the daily-driver box had, not a weaker one.

Captain's framing (s450, `nixps` `[main]`): *"what if next version of water-spider had
wsforge's confinement built into it, just jagents or both."*

## Success criteria

- [ ] `Dockerfile.v2` (GPU compute pod) gets a confined `jagent` identity — dispatched
      inference/training work runs there, not as root.
- [ ] `Dockerfile.runpod` (the CPU-only always-on control pod — its own header: *"manages your
      OTHER RunPod pods... without needing a laptop left open"*) gets **both** `jagent` and
      `jforeman` — this is the pod a human actually SSHes into and drives, the same role nixps'
      own `[main]` box plays. `jforeman` gets `agent-escalate` reach; `jagent` doesn't.
- [ ] `Dockerfile.train` evaluated the same way as `Dockerfile.v2` once the pattern is proven —
      not blocking the first pass.
- [ ] The RunPod/HF/SSH credentials the pod needs are reachable to the tier that legitimately
      needs them (likely `jforeman` on the control pod for orchestration calls) and NOT sitting
      in every confined worker's ambient environment by default — mirrors the
      `SECURE_ENV_PASSWORD` fix from `wsforge` s450 (fetch-fresh-per-call, never a persistent
      export every subprocess inherits).
- [ ] Proven live on one real pod boot (build the image, launch it via `water-spider create`,
      confirm the confined identity actually can't touch what it shouldn't — same live-verified
      bar `wsforge`'s own containment work held itself to, not just "the Dockerfile has a
      `USER` line").

## Technical approach

- Both current bases are Ubuntu (`runpod/base:...ubuntu2204` for the control pod,
  `runpod/pytorch:...ubuntu2404` for v2) — `bwrap` is a plain `apt install bubblewrap`, and
  `jagent-run`/`jagent-confine`/the `profile.d` scripts (`40-agent-vault.sh`,
  `45-jforeman-harness-policy.sh`, `50-agent-scope.sh`, `55-agent-squad.sh`,
  `60-cargo-target.sh`) are already distro-agnostic shell. Only `wsforge-configure`'s
  Arch-specific bits (`pacman`, limine, btrfs balance timers) don't apply in a container and
  should be left behind, not ported.
- Provisioning bakes into the image at `docker build` time (a `RUN` step doing the
  `useradd`/vault-dir/profile.d setup `wsforge-configure`'s "Agent containment tiers" step
  already does on bare metal), not at pod boot — no pod-start latency cost, unlike wsforge's
  live-box chroot flow.
- Pods are inherently disposable/replace-don't-mutate already (torn down and redeployed for
  updates, no running-system-mutation story) — this is actually a *better* fit for the
  nakshatra-style "immutable image, atomic replace" model than nixps itself is (see
  `wsforge/docs/IMMUTABLE-CONFINEMENT.md`, which found that model wrong for a continuously
  `pacman`-updated daily driver). Worth leaning into here rather than working around it.
- Start with `Dockerfile.runpod` — smaller, non-GPU surface, proves the pattern before touching
  the GPU build's much longer/costlier iteration loop.

## Files to modify

- `Dockerfile.runpod` — add the `jagent`+`jforeman` user/group/vault/profile.d provisioning.
- `Dockerfile.v2` (and later `Dockerfile.train`) — add `jagent` only.
- `docker/post_start.sh` / `docker/water-spider-pod-init.sh` — whatever currently runs as the
  pod's effective entrypoint identity needs to hand off to the right tier, not stay root.
- New: a water-spider-side copy of the relevant `wsforge` `fixes/` scripts (or a documented
  decision to depend on them directly if that's viable across repos) — needs a call on whether
  this vendors wsforge's scripts or references them.

## Non-goals

- Not implementing this session — this ticket exists so the idea has a durable home instead of
  living only in a chat transcript.
- Not porting `wsforge-configure` wholesale, or anything Arch/btrfs/limine-specific.
- Not deciding here whether water-spider vendors `wsforge`'s scripts or takes a dependency on
  them some other way — that's an open question for whoever picks this up.
