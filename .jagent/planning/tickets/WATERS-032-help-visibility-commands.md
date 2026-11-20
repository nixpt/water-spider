# WATERS-032 — `--help` lists top, logs and watch

| Field | Value |
|-------|-------|
| **ID** | WATERS-032 |
| **Priority** | P2 |
| **Status** | Open |
| **Phase** | Documentation |
| **Assignee** | — |
| **Dependencies** | WATERS-028 (merged, v0.8.0) |
| **Estimated effort** | XS |

## Problem

In v0.8.0 the dispatch handles `ps`, `gpu`, `top`, `logs` and `watch`, but the usage header that `--help` prints
only lists `ps` and `gpu`. `top`, `logs [--sync|--follow]` and `watch --json [--interval N] [--out FILE]` are
missing, so users who rely on `--help` don't find them. (Found by arisu after fast-forwarding to f367ac9.)

## Success criteria

- [ ] The usage header lists `top`, `logs` and `watch` with their flags, matching `docs/cli-reference.md`.
- [ ] A test asserts every dispatched subcommand appears in `--help` output, so the two can't drift again.
- [ ] `watch` without `--json` stays an explicit error until a text mode exists, and `--help` says so.
