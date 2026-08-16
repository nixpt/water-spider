# WATERS-005 — Bootstrap versioning, remote, and initial release

| Field | Value |
|-------|-------|
| **ID** | WATERS-005 |
| **Priority** | P1 |
| **Status** | Backlog |
| **Phase** | Release readiness |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-001, WATERS-002 |
| **Estimated effort** | M |

## Problem

The release workflow expects an existing `v*` tag and a version surface, but the repository has neither a `VERSION` file nor tags. The local checkout also has no Git remote, despite documentation naming `nixpt/water-spider` as the intended public origin.

## Reproduction

1. Run `git remote -v` and `git tag --list`; both are empty in the current checkout.
2. Run `test -f VERSION`; it fails.
3. Run `BUMPVER_DRY_RUN=1 ./scripts/bump-version.sh`; it reports that no prior tag exists and performs no release.

## Success criteria

- [ ] The repository has one documented version surface consumed by `bump-version.sh`.
- [ ] The authorized canonical GitHub repository is created or confirmed and `origin` points to it.
- [ ] CI and branch protection pass before publication.
- [ ] An initial semantic-version tag and GitHub release are published intentionally.
- [ ] A subsequent dry run demonstrates that conventional commits select the expected next version.

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
