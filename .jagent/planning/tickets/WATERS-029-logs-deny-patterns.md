# WATERS-029 — `logs`: widen the credential deny patterns

| Field | Value |
|-------|-------|
| **ID** | WATERS-029 |
| **Priority** | P1 |
| **Status** | Open |
| **Phase** | Operations |
| **Assignee** | — |
| **Dependencies** | WATERS-028 (merged, v0.8.0) |
| **Estimated effort** | S |

## Problem

`water-spider logs <pod> <path>` restricts reads to an allowlist (`/workspace`, `/var/log`, `/tmp`), and inside it refuses
credential-looking names. usagi's review of #14 (head f9baffb,
https://github.com/nixpt/water-spider/pull/14#issuecomment-7032373290) found names the deny list misses, which are
still served if they sit under an allowed root: for example `PASSWORD.txt` (case), `.bash_history`, and similar
shell or tool history and credential files.

## Success criteria

- [ ] The deny check is case-insensitive.
- [ ] It also denies shell and REPL history (`.bash_history`, `.zsh_history`, `.python_history`, `.lesshst`, …),
      `.netrc`, `.git-credentials`, `.npmrc`/`.pypirc`, `*.pem`/`*.key`/`id_*` (non-.pub), `.env*`, files under
      `.ssh/`, `.aws/`, `.config/gcloud/`, `.huggingface/`/`hf` token files, and names containing
      `passw`, `secret`, `token`, `credential`.
- [ ] The check runs on the pod against the `readlink -f` resolved path (as the allowlist does), and locally.
- [ ] Tests cover each new class, including mixed case, through the fakes.

## Notes

Keep it a deny list layered on the allowlist; do not widen the allowlist. Redaction of file *contents* stays best effort.
