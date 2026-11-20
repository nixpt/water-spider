# Operations

## Prerequisites

Install `runpodctl`, `jq`, `ssh`, and `pgrep`. GraphQL-only creation flags also
need `curl`. Authenticate with `runpodctl` so `~/.runpod/config.toml` exists, or
scope `RUNPOD_API_KEY` to the invocation. Keep SSH and registry credentials out
of logs and source control.

## Cost-safe lifecycle

```sh
water-spider status
water-spider gpus --available
water-spider create --image IMAGE --gpu "GPU NAME" \
  --idempotency-key SESSION-ID
water-spider connect POD-ID
water-spider tunnel POD-ID --port 8080:8080
# perform the work and pull every artifact worth keeping
water-spider teardown POD-ID
water-spider list
```

Before creation, set an explicit maximum runtime and expected cost. Use an
idempotency key whenever a human or automation may repeat a request. If create
returns an ambiguous error, inspect `water-spider list` before retrying.

Teardown is intentionally interactive. Pull results first, confirm the prompt,
and retain the final independent absence check in operational logs.

## Pod visibility

Read-only views of what runs inside a pod, with no hand-ssh:

```sh
water-spider ps  POD-ID [--limit N]
water-spider gpu POD-ID [--watch 5]
# no RunPod API needed with an explicit endpoint, like `tunnel`:
water-spider ps --host 217.138.104.26 --pod-port 10258
```

Each refresh is ONE ssh round trip: a single read-only script sent on stdin
(`ssh ... 'bash -s'`) with ControlMaster reuse (private 0700 socket dir,
ControlPersist 60 s), so `--watch` (N >= 5) never opens a connection storm.
The script writes nothing on the pod (not even /tmp), installs nothing and
never reads `/proc/*/environ`; a missing tool degrades (`nvidia-smi absent`,
`ss` -> `netstat` -> `/proc/net/tcp`). Token-like values (`*_TOKEN=`, `*_KEY=`,
`--token X`, `Bearer`, `hf_`, `sk-`, `rp_`) are redacted on the pod and again
locally. CPU/RAM come from the container cgroup, not host `/proc/meminfo`.

Flags (a warning line at the end): public listener other than sshd, GPU process
with no identifiable/live parent (also shown when the container cannot see
host-pid compute apps), `/` or `/workspace` over 90%, VRAM over 95%. The GPU
query fields start with the MCP `gpu_status` set so both surfaces agree.
More views, same rules (one round trip per tick, ControlMaster, read-only, redaction):

```sh
water-spider top POD-ID [--interval N] [--once] [--t0-balance USD]   # one-screen dashboard, N >= 5
water-spider logs POD-ID /workspace/results/run.log [--lines N]      # read-only tail
water-spider logs POD-ID --sync --follow                              # /workspace/sync.txt, one long ssh
water-spider watch POD-ID --json [--interval N] [--out FILE]          # one JSON line per tick
```

`top` adds container CPU use (cgroup usage delta), net rx/tx (non-loopback) and, when the
RunPod API answers, spend since T0 (the first balance seen, or `--t0-balance`); it is omitted
otherwise. `logs` requires a plain absolute path under `/workspace`, `/var/log` or `/tmp`
and refuses paths that can hold credentials. The deny list is case-insensitive and layered on
the allowlist (it never widens it): shell and REPL history (`*_history`, `.lesshst`, `.viminfo`),
`.netrc`, `.git-credentials`, `.npmrc`, `.pypirc`, `.pgpass`, `*.pem`/`*.key`/`*.p12`/`*.pfx`/`*.jks`,
non-`.pub` `id_*`, `.env*`, anything under `.ssh/`, `.aws/`, `.config/`, `.huggingface/`, `.git/`,
and any name containing `passw`, `secret`, `token` or `credential`. WATERS-035 adds `authorized_keys`,
`known_hosts`, `.gitconfig`, `*.kdbx`, `*.tfstate`, `*.tfstate.backup`, `*.tfvars`, `*kubeconfig*`,
anything under `.kube/`, `*-sa.json`, `service-account*.json`, `application_default_credentials.json`,
`.boto`, `.s3cfg`, `.docker/config.json`, and under `/var/log` the login records `btmp`, `wtmp`,
`lastlog`, `faillog`, `auth.log*` and `secure*`. It runs locally on the literal
path and again on the pod on the `readlink -f` resolved path, from one shared text
(`ws_logs_guard_src`), so a symlink into a denied file is refused. On the pod the script opens the
file once (fd 3), re-checks that `/proc/self/fd/3` still resolves inside the allowlist and passes the
deny list, and then `tail` reads fd 3 only (no re-open of the path, so a symlink swapped in after the
check cannot redirect the read). The open itself is bounded (WATERS-036): a FIFO or device swapped in
after the `-f` check would block `exec 3<` until a writer appears, so a bash watchdog (`sleep`, present
everywhere bash is) TERMs the script after `WS_LOGS_OPEN_TIMEOUT` seconds (default 5) and it refuses with
"not a regular file, or the open timed out"; the fd check still refuses FIFOs and devices that open at once. `--follow` uses `tail -f --pid` on that fd: it follows the opened
inode, so after a log rotation re-run `logs`; the tail exits with the ssh session. `watch` requires `--json` (no text mode yet; without it the command errors). `watch --json` emits ps + gpu + mem + disk + net + listeners
+ spend + flags per tick (stdout, and appended to `--out`, mode 0600) for guards and a future
command-center panel. Redaction is best effort: attached short options (`-pSECRET`) and
unquoted spaced values can leak, and hex runs are handled by length (WATERS-033): a run of exactly 40 (git commit) or 64 (SHA-256 digest)
hex characters is shown (`zorro=<sha>`, `commit <sha>`, `sha256:<digest>`), unless a secret-like word
(token, key, secret, pass, credential, auth, cookie, jwt, pwd) appears earlier on the same line, as in
`API_KEY=<hex>`, `--token <hex>` or `Bearer <hex>`; every other run of 40+ hex is masked. Residual risk: a
bare 40/64-hex secret on a line with no secret-like word is no longer masked. When unsure the rule masks.
The remote and local passes use the one `ws_redact_prog`.

Tests: `tests/run.sh` (fakes) and `WS_TEST_DOCKER=1 tests/run.sh` (real remote
script in a locked-down container). `tests/logs-exec.sh bash|docker` EXECUTES the pod-side `logs`
script: each allowed root, `/etc/shadow`, `..`, `//`, `/./`, symlinks out of `/workspace`, denied
names (mixed case), a symlink swapped between the check and the open, and no orphan `tail`. The
docker mode uses `--cap-drop ALL --network none --read-only` (tmpfs only for `/workspace` and `/tmp`).
`LOGS_MUTATE=allowlist|deny|fdcheck` sabotages the script; `run.sh` asserts the suite then fails.

## Private images

`--registry-auth-id` is a GraphQL-only field and defaults from
`WATER_SPIDER_REGISTRY_AUTH_ID`. Use
[`docker/create-registry-auth.sh`](../docker/create-registry-auth.sh) to create
the RunPod registry record. Never commit the Docker Hub token or API key.

## Validation status

Recorded live evidence currently covers:

- pod creation and direct SSH;
- private-image pulls with registry authentication;
- GPU initialization and CUDA-backed llama.cpp inference;
- local SSH tunneling and a real HTTP completion through it;
- teardown followed by an independent list confirming absence.

Still awaiting focused live evidence under WATERS-003:

- a small `send`/`receive` round trip;
- `recipe serve` as the orchestrating command rather than equivalent manual
  server-plus-tunnel steps;
- GUI forwarding through xpra or raw X11;
- snapshot manifest collection from a live pod.

Do not infer those four workflows are live-proven from the mocked suite.
