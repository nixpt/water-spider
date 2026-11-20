# WATERS-035 — `logs`: close the deny-list gaps from the #16 review

| Field | Value |
|-------|-------|
| **ID** | WATERS-035 |
| **Priority** | P2 |
| **Status** | Open |
| **Phase** | Operations |
| **Assignee** | ann |
| **Dependencies** | WATERS-029 (merged, v0.8.1) |
| **Estimated effort** | S |

## Problem

usagi's #16 review (finding 5, head e742c32,
https://github.com/nixpt/water-spider/pull/16#issuecomment-7033295327) read the `ws_logs_guard_src` patterns and
found credential and security files they do not match. `logs` would serve these if they sit under an allowed root
(/workspace, /var/log, /tmp):

- SSH: `authorized_keys`, `known_hosts`
- `.gitconfig` (can hold credential helpers and tokens in `url.*.insteadOf`)
- password stores: `*.kdbx`
- Terraform: `*.tfstate`, `*.tfstate.backup`, `*.tfvars`
- Kubernetes: `kubeconfig`, `*/.kube/*`
- cloud credentials: service-account JSON (for example `*-sa.json`, `service-account*.json`,
  `application_default_credentials.json`), `.boto`, `.s3cfg`, `.docker/config.json`
- under /var/log: `btmp`, `wtmp`, `lastlog`, `auth.log*`, `secure*` (login and auth records)

## Success criteria

- [ ] `ws_logs_guard_src` refuses every name above, case-insensitively, on both the pod pass (`readlink -f` path)
      and the local pass. It stays one source text.
- [ ] Each name is a case in `tests/logs-exec.sh` (bash and docker), including a symlink with an innocent name
      that points at one of them.
- [ ] The `deny` mutation still fails the new cases (the mutation count goes up in the PR note).
- [ ] Benign neighbours still pass: `app.log`, `train.log`, `/var/log/syslog`, `nginx/access.log`.
- [ ] README and `docs/operations.md` list the new denied names.

## Notes

Name-based, like the rest of the deny list. When unsure, deny: a refused log costs a retry with a different path,
and a served credential is a leak. Read-only tool; tests use the fakes or `--network none` docker, never a pod.
