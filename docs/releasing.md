# Releasing

## Current state

The canonical public repository is
[`nixpt/water-spider`](https://github.com/nixpt/water-spider), and local
`origin` points there. Docker images and RunPod templates are already published,
but the repository has no project `VERSION` file and no `v*` Git tag.

Docker tag `2.9.0` denotes the pinned `runpodctl` release used by the one-shot
image. It is not water-spider's semantic version.

## Automation contract

`.github/workflows/release.yml` runs `scripts/bump-version.sh` after pushes to
`main`. The script:

- reads a root `VERSION` file for this Bash project;
- finds the latest `v*` tag;
- infers major/minor/patch from conventional commit messages;
- updates the version and optional changelog;
- commits, tags, and pushes the result.

It deliberately cannot bootstrap an unversioned repository. WATERS-005 remains
open until the owner chooses the initial project version, adds `VERSION`, creates
the matching initial tag/release, and verifies the next dry-run bump.

## Image publication

Project releases and container publication are separate surfaces. Image build
and live-validation details belong in [`docker/README.md`](../docker/README.md).
Do not reuse a dependency version as a project release merely because an image
already carries that tag.
