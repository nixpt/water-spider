# WATERS-033 — redaction: stop masking git commit ids

| Field | Value |
|-------|-------|
| **ID** | WATERS-033 |
| **Priority** | P3 |
| **Status** | Done (v0.8.2) |
| **Phase** | Operations |
| **Assignee** | ann |
| **Dependencies** | WATERS-028 (merged, v0.8.0) |
| **Estimated effort** | S |

## Problem

`ws_redact_prog` (bin/water-spider, v0.8.0 line 975) ends with a catch-all rule that masks any run of 40 or more hex
characters:

    s/(^|[^A-Za-z0-9])[0-9a-fA-F]{40,}([^A-Za-z0-9]|$)/\1<redacted>\2/g

A full git commit id is exactly 40 hex characters, so commit ids are masked. vega saw this on 2026-11-20 in
`water-spider logs 8lkabn83yugmnf --sync` (and `ps`): sync.txt lines read `zorro=<redacted>` where a commit id
should be. On a coordination file, the commit id is the useful part.

## Success criteria

- [ ] A 40-hex value (SHA-1 commit) or 64-hex value (SHA-256 digest) is shown when the key in front of it is not
      secret-like, for example `zorro=<sha>`, `commit <sha>`, `head=<sha>`, `sha256:<digest>`, or a bare sha on a
      `git log` line.
- [ ] Hex values stay masked when the key is secret-like (`*token*`, `*key*`, `*secret*`, `*pass*`, `*auth*`,
      `*jwt*`, …), as rules 968/973 already do. Also keep masking hex runs that are not exactly 40 or 64 characters,
      unless review agrees to drop that rule.
- [ ] Tests:
  - [ ] `zorro=<40hex>`, `commit <40hex>`, `sha256:<64hex>` pass through unchanged;
  - [ ] `API_KEY=<40hex>`, `--token <40hex>`, `Authorization: Bearer <hex>` stay masked;
  - [ ] the remote and local passes agree (`ws_redact_prog` is the single source of both).
- [ ] The README and `docs/operations.md` redaction notes are updated.

## Notes

Low priority, and a usability fix rather than a security fix. When unsure, keep masking: a false positive costs a
commit id, a false negative leaks a credential. Read-only tool, so no pod action is needed.
