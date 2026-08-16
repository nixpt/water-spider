# WATERS-011 — Create the project logo and repository asset kit

| Field | Value |
|-------|-------|
| **ID** | WATERS-011 |
| **Priority** | P2 |
| **Status** | Done |
| **Phase** | Project metadata |
| **Assignee** | codex |
| **Dependencies** | WATERS-006 |
| **Estimated effort** | S |

## Problem

The project has no visual identity or reusable image assets. Its README,
repository metadata, package listings, and future web surfaces therefore have
no consistent mark.

## Success criteria

- [x] A transparent, high-resolution master logo represents water-spider's role.
- [x] Standard avatar, icon, and favicon sizes are derived from the same master.
- [x] A wide repository banner uses the same visual language.
- [x] Asset intent, dimensions, palette, and regeneration provenance are documented.
- [x] The README displays repository-local brand art with useful alt text.

## Non-goals

- Changing the GitHub account avatar or other organization-wide branding.
- Defining a broad design system or adding product UI.

## Resolution

Created a geometric water-strider mark that joins a water ripple with network
nodes, using a navy/cyan palette and a single orange safety accent. Added a
transparent master, deterministic raster sizes, a multi-resolution favicon,
and a matching wide banner. The source generation image and prompts are
documented in `assets/README.md`; the README now uses the wide banner.
