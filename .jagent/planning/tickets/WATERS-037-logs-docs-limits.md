# WATERS-037 — docs: state the `logs` guard's known limits

| Field | Value |
|-------|-------|
| **ID** | WATERS-037 |
| **Priority** | P3 |
| **Status** | Open |
| **Phase** | Documentation |
| **Assignee** | ann |
| **Dependencies** | WATERS-029/030 (merged, v0.8.1) |
| **Estimated effort** | XS |

## Problem

usagi's #16 review (findings 2, 3, 4, 6, head e742c32,
https://github.com/nixpt/water-spider/pull/16#issuecomment-7033295327) found behaviour the docs do not state:

- **`--follow` no longer follows rotation.** `tail -F` became `tail -f` on fd 3, so a log rotated by rename is not
  followed to the new file. This is inherent to the fd approach and the right trade, but it is a behaviour change.
- **The guard is name-based, not content-based.** A hardlink to a credential under an innocent name passes (limited
  by `protected_hardlinks`). A rename of the same inode between check and re-check passes, but that needs write
  access to the secret's directory. The `*.pub` exception trusts the name, so a private key renamed `foo.pub` is
  served.
- **Over-deny.** `*token*`, `*passw*` and `*/.config/*` also refuse benign paths, for example a `tokenizer/`
  directory of model files. That is the safe direction, but users should know why a log was refused and what to do.

## Success criteria

- [ ] `docs/operations.md` has a "logs: what the guard does and does not cover" section with the three points above.
- [ ] The `--follow` rotation note also appears in `docs/cli-reference.md` and the CHANGELOG (Unreleased).
- [ ] The refusal message names the rule that matched (allowlist, deny name, not a regular file), so a user hitting
      the `tokenizer/` case can tell why. If that needs a code change, keep it to the message text and add a test.
- [ ] No wording claims the guard is content-safe.
