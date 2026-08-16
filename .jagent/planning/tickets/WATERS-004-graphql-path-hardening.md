# WATERS-004 — Harden GraphQL dependencies and input construction

| Field | Value |
|-------|-------|
| **ID** | WATERS-004 |
| **Priority** | P0 |
| **Status** | Backlog |
| **Phase** | Core health |
| **Assignee** | unassigned |
| **Dependencies** | WATERS-002 |
| **Estimated effort** | M |

## Problem

The GraphQL create path calls `curl` without declaring it as a required dependency and constructs the mutation by interpolating user-controlled strings. Quotes, backslashes, or malformed numeric/list values can produce invalid GraphQL and make error behavior inconsistent with the normal `runpodctl` path.

## Reproduction

1. Run `rg -n 'need curl|curl -sS|local query=' bin/water-spider`.
2. Observe that `curl` is used but never checked by `need`.
3. Inspect `ws_create_via_graphql`; values such as name, image, GPU, and ports are inserted directly into the mutation text.

## Success criteria

- [ ] Entering the GraphQL path fails early with a clear dependency error when `curl` is unavailable.
- [ ] String values are encoded safely through GraphQL variables or equivalent JSON-safe construction.
- [ ] Numeric and enum options are validated before any network request.
- [ ] Mocked tests cover quotes, backslashes, invalid numbers, malformed CUDA lists, GraphQL errors, and transport failure.

## Technical approach

- Declare `curl` only where the GraphQL path needs it, preserving normal-path dependency behavior.
- Prefer a static mutation with a variables object assembled by `jq`.
- Validate constrained inputs locally and return actionable messages.

## Files to modify

- `bin/water-spider` — dependency check, validation, and safe request construction.
- `tests/` — GraphQL-path regression coverage.
- `README.md` — accurately list conditional dependencies if needed.

## Non-goals

- Replacing `runpodctl` for subcommands it already supports.
