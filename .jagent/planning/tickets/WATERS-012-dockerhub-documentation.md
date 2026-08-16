# WATERS-012 — Publish maintained Docker Hub documentation

| Field | Value |
|-------|-------|
| **ID** | WATERS-012 |
| **Priority** | P2 |
| **Status** | Done |
| **Phase** | Project metadata |
| **Assignee** | codex |
| **Dependencies** | WATERS-011 |
| **Estimated effort** | S |

## Problem

Docker Hub is a primary discovery surface for the three published image roles,
but its documentation is not sourced or maintained in the repository. Users
can therefore miss the tag distinctions and the project's cost-safety model.

## Success criteria

- [x] A registry-focused overview explains the `latest`, `pod`, and `v2` roles.
- [x] The overview includes the brand banner, quick start, safety guidance,
      source links, and license.
- [x] A credential-safe script updates the Docker Hub short and full descriptions.
- [x] GitHub Actions republishes the description when its source changes.
- [x] The detailed Docker guide documents manual and automated publication.

## Non-goals

- Rebuilding or republishing container images.
- Changing RunPod templates or creating billable resources.

## Resolution

Added `docker/DOCKERHUB.md` as the canonical registry landing page and a small
Docker Hub API publisher that reads credentials only from environment variables.
Added a path-filtered GitHub Actions workflow and linked the publication process
from the detailed Docker guide.
