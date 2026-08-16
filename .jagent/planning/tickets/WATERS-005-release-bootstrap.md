# WATERS-005 — Bootstrap versioning, remote, and initial release

| Field | Value |
|-------|-------|
| **ID** | WATERS-005 |
| **Priority** | P1 |
| **Status** | Done |
| **Phase** | Release readiness |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-001, WATERS-002 |
| **Estimated effort** | M |

## Problem

The canonical public remote is configured and current work has been pushed, but
the release workflow still has neither a `VERSION` surface nor an initial `v*`
tag from which to calculate subsequent releases.

## Reproduction

1. Run `git remote -v` and confirm `origin` is `nixpt/water-spider`.
2. Run `git tag --list` and confirm there is no project tag.
3. Run `test -f VERSION`; it fails.
4. Run `BUMPVER_DRY_RUN=1 ./scripts/bump-version.sh`; it reports that no prior tag exists and performs no release.

## Success criteria

- [x] The repository has one documented version surface consumed by `bump-version.sh`.
- [x] The authorized canonical GitHub repository is confirmed and `origin` points to it.
- [x] CI and branch protection pass before publication.
- [x] The initial semantic-version tag is published intentionally; GitHub Release objects are intentionally deferred until 1.0 by project policy.
- [x] An isolated subsequent dry run demonstrates that a `fix:` commit selects `v0.1.1`.

## Technical approach

- Add a `VERSION` file with an explicitly chosen initial version.
- Confirm repository ownership/visibility before creating or configuring the remote.
- Push main, establish the initial tag manually as required by the bump script, and verify the release workflow.

## Files to modify

- `VERSION` — establish the release version surface.
- `README.md` — document installation from the canonical remote and released version where appropriate.
- `.github/workflows/release.yml` — adjust only if bootstrap validation reveals a workflow defect.

## Non-goals

- Creating a remote or publishing a release without repository-owner authorization.

## Resolution

Confirmed the public origin, established root `VERSION` at 0.1.0, published
matching tag `v0.1.0`, and added a bootstrap guard so tagged HEAD is a no-op.
The isolated release test proves the next `fix:` commit selects 0.1.1. The
active minimum ruleset protects `main` without blocking the release bot.
Pre-1.0 versions remain tags rather than GitHub Release objects by policy.
