# Changelog

All notable changes to water-spider are recorded here. The format loosely
follows [Keep a Changelog](https://keepachangelog.com/); released versions must
match `v*` Git tags. Once the initial tag exists, `scripts/bump-version.sh`
appends entries mechanically on pushes to `main`.

## [Unreleased]

- Add dual MIT/Apache-2.0 licensing and public contribution guidance.
- Add deterministic command tests and harden GraphQL pod creation.
- Add standalone, CPU-control-pod, and CUDA/llama.cpp image variants.

The repository has not established its first project-version tag yet. Docker
image tag `2.9.0` identifies the bundled `runpodctl` release and is not a
water-spider semantic-version claim.
