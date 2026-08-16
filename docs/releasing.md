# Releasing

## Current state

The canonical public repository is
[`nixpt/water-spider`](https://github.com/nixpt/water-spider), and local
`origin` points there. Docker images and RunPod templates are already published.
The project version surface is the root `VERSION` file; the initial tag is
`v0.1.0`.

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

The script intentionally does not invent the initial version. Bootstrap uses a
manually chosen `VERSION` plus matching tag. An exact-tag guard prevents that
initial push from immediately consuming a patch release; later untagged pushes
resume conventional-commit bumping.

Pre-1.0 releases are Git tags without GitHub Release objects. Beginning at 1.0,
the script also creates a GitHub Release with generated notes.

## Image publication

Project releases and container publication are separate surfaces. Image build
and live-validation details belong in [`docker/README.md`](../docker/README.md).
Do not reuse a dependency version as a project release merely because an image
already carries that tag.
