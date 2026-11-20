#!/usr/bin/env bash
# WATERS-031: EXECUTE the pod-side `logs` script (allowlist, deny list, fd re-check)
# instead of grepping it.
#   tests/logs-exec.sh bash     plain bash, fixtures in a temp dir, roots overridden
#   tests/logs-exec.sh docker   the real roots (/workspace /var/log /tmp) inside
#                               `docker run --cap-drop ALL --network none --read-only`
#                               (tmpfs for /workspace and /tmp only; no pod, no sshd)
# LOGS_MUTATE=allowlist|deny|fdcheck sabotages the generated script; the suite must
# then FAIL (run.sh asserts that, so a silently weakened check cannot pass).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATH="/usr/bin:/bin:$PATH"   # real sleep/readlink even when run.sh put the fakes first
CLI="$ROOT/bin/water-spider"
MODE="${1:-bash}"; B=""
IMG="${REHEARSAL_IMAGE:-ubuntu:22.04}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

if [ "$MODE" = docker ]; then
  docker image inspect "$IMG" >/dev/null 2>&1 || { echo "skip: image $IMG not present locally (no pull)"; exit 0; }
  W=/workspace; L=/var/log; T=/tmp; ROOTS=""
  VARNEEDLE=installed; LOGF=dpkg.log   # present in the stock image; /var/log stays read-only
else
  B="$TMP/lx"; W="$B/workspace"; L="$B/var/log"; T="$B/tmp"; ROOTS="$W $L $T"
  VARNEEDLE=varlog-line; LOGF=dpkg.log
fi

mutate() {
  # shellcheck disable=SC2016  # the sed programs are literal
  case "${LOGS_MUTATE:-}" in
    allowlist) sed 's/^ws_logs_in_roots() {/ws_logs_in_roots() { return 0;/' ;;
    deny)      sed 's/^ws_logs_denied() (/ws_logs_denied() ( return 1;/' ;;
    fdcheck)   sed 's/^  if ! ws_logs_in_roots "\$rr" .*; then$/  if false; then/' ;;
    *)         cat ;;
  esac
}

# Fixture + (optional) race shim, run inside the sandbox before the script.
setup() {
  cat <<SETUP
W='$W'; L='$L'; T='$T'
[ "$MODE" = docker ] || rm -rf '$B'
mkdir -p "\$W/results" "\$W/.ssh" "\$W/.aws" "\$W/.config/gcloud" "\$W/.huggingface" "\$T" 2>/dev/null
[ "$MODE" = docker ] || mkdir -p "\$L"
echo alpha-line > "\$W/results/run.log"; echo mixed-line > "\$W/results/Mixed.LOG"
[ -e "\$L/$LOGF" ] || echo varlog-line > "\$L/$LOGF" 2>/dev/null
echo tmp-line > "\$T/ws.log"; echo pub-line > "\$W/id_rsa.pub"
ln -s /etc/passwd "\$W/passwd-link.log"; ln -s /etc/os-release "\$W/os-link.log"
ln -s "\$W/results/run.log" "\$W/ok-link.log"
for n in PASSWORD.txt .bash_history .zsh_history .python_history .lesshst .NETRC .git-credentials .npmrc .pypirc \
         Id_Rsa x.PEM s.KEY .env .env.local My_Secret.log .ssh/config .aws/credentials .config/gcloud/a.db .huggingface/hf; do
  echo fake-credential-fixture > "\$W/\$n"
done
ln -s "\$W/.bash_history" "\$W/innocent.log"
# WATERS-035: more credential/security files, plus benign neighbours
mkdir -p "\$W/.kube" "\$W/.docker" "\$W/nginx" "\$W/tf" 2>/dev/null
for n in .ssh/authorized_keys .ssh2_dummy AUTHORIZED_KEYS known_hosts .gitconfig db.kdbx tf/terraform.tfstate tf/terraform.tfstate.backup \\
         tf/prod.TFVARS kubeconfig .kube/config sa-key-sa.json service-account-prod.json application_default_credentials.json \\
         .boto .s3cfg .docker/config.json race2.log; do
  echo fake-credential-fixture > "\$W/\$n"
done
ln -s "\$W/tf/terraform.tfstate" "\$W/innocent-state.log"; ln -s "\$W/.kube/config" "\$W/innocent-kube.log"
echo app-line > "\$W/app.log"; echo train-line > "\$W/train.log"; echo nginx-line > "\$W/nginx/access.log"
[ "$MODE" = docker ] || { echo syslog-line > "\$L/syslog"; mkdir -p "\$L/nginx"; echo nginx-var-line > "\$L/nginx/access.log"; }
echo race-target > "\$W/results/race.log"
mkdir -p "\$T/shim"
cat > "\$T/shim/readlink" <<'SHIM'
#!/bin/bash
out="\$(/usr/bin/readlink "\$@")"; rc=\$?
if [ -n "\${RACE_FLAG:-}" ] && [ ! -e "\$RACE_FLAG" ]; then : > "\$RACE_FLAG"; ln -sf /etc/os-release "\$RACE_TARGET"; fi
printf '%s\n' "\$out"; exit \$rc
SHIM
chmod +x "\$T/shim/readlink"
# WATERS-036: swap window between the open and the fd re-check: on the 2nd readlink (the /proc/self/fd/3 one)
# the opened file is renamed to a denied name, so the fd now resolves to a path the deny list refuses
sed -i '2i if [ -n "\${RACE2_TO:-}" ]; then c="\$(cat "\$RACE2_CNT" 2>/dev/null || echo 0)"; c=\$((c+1)); echo "\$c" > "\$RACE2_CNT"; [ "\$c" = 2 ] \&\& mv -f "\$RACE2_FROM" "\$RACE2_TO"; fi' "\$T/shim/readlink"
# WATERS-036: between the check and the open, swap the target for a FIFO. Overriding the \`[\` builtin with a
# function (loaded through BASH_ENV) is the only seam between the -r check and the open.
cat > "\$T/shim/hook.sh" <<'HOOK'
[() { builtin '[' "\$@"; local rc=\$?
  if [[ -n \${FIFO_TARGET:-} && \${2:-} == -r && \${3:-} == "\$FIFO_TARGET" && ! -e \${FIFO_FLAG:-/nonexistent} ]]; then
    : > "\$FIFO_FLAG"; /bin/rm -f "\$FIFO_TARGET"; /usr/bin/mkfifo "\$FIFO_TARGET"
  fi
  return \$rc; }
HOOK
SETUP
}

sandbox() {   # $1 extra env prefix; stdin: the generated script
  local pre="$1"
  local cmd; cmd="$(setup)"$'\n'"$pre"$'\nbash -s'
  if [ "$MODE" = docker ]; then
    docker run --rm -i --cap-drop ALL --security-opt no-new-privileges --network none --read-only \
      --tmpfs /workspace:mode=1777 --tmpfs /tmp:mode=1777,exec "$IMG" bash -c "$cmd"
  else
    bash -c "$cmd"
  fi
}

fails=0; n=0
# expect KIND NEEDLE PATH [env-prefix] : KIND ok => rc 0 + needle in output; refuse => rc 2 + needle, no leak
expect() {
  local kind="$1" needle="$2" path="$3" pre="${4:-}" out rc=0
  n=$((n + 1))
  out="$("$CLI" _logs-script "$path" 20 0 ${ROOTS:+"$ROOTS"} | mutate | sandbox "$pre" 2>&1)" || rc=$?
  local want=0; [ "$kind" = refuse ] && want=2
  if [ "$rc" -eq "$want" ] && printf '%s' "$out" | grep -Fq -- "$needle" \
     && ! printf '%s' "$out" | grep -Eq 'root:|PRETTY_NAME|fake-credential-fixture'; then
    echo "ok - [$MODE] $kind $path"
  else
    echo "not ok - [$MODE] $kind $path (rc=$rc want=$want needle='$needle')"; printf '%s\n' "$out" | head -3 | sed 's/^/    /'; fails=$((fails + 1))
  fi
}

DOTS="$W/../../../../../../../../../.."
expect ok alpha-line "$W/results/run.log"
expect ok "$VARNEEDLE" "$L/$LOGF"
expect ok tmp-line "$T/ws.log"
expect ok alpha-line "$W//results/run.log"
expect ok alpha-line "$W/./results/run.log"
expect ok alpha-line "$W/ok-link.log"
expect ok mixed-line "$W/results/Mixed.LOG"
expect ok pub-line "$W/id_rsa.pub"
expect refuse outside /etc/shadow
expect refuse outside /etc//shadow
expect refuse outside //etc/os-release
expect refuse outside /etc/./os-release
expect refuse outside "$DOTS/etc/os-release"
expect refuse outside "$W/results/../../../../../../../../etc/os-release"
expect refuse outside "$W/os-link.log"
expect refuse outside "$W/passwd-link.log"
expect refuse outside /proc/self/environ
expect refuse "not a readable regular file" "$W/results"
expect refuse "not a readable regular file" "$W/results/missing.log"
for d in PASSWORD.txt .bash_history .zsh_history .python_history .lesshst .NETRC .git-credentials .npmrc .pypirc \
         Id_Rsa x.PEM s.KEY .env .env.local My_Secret.log .ssh/config .aws/credentials .config/gcloud/a.db .huggingface/hf innocent.log; do
  expect refuse "can hold credentials" "$W/$d"
done
for d in .ssh/authorized_keys AUTHORIZED_KEYS known_hosts .gitconfig db.kdbx tf/terraform.tfstate tf/terraform.tfstate.backup \
         tf/prod.TFVARS kubeconfig .kube/config sa-key-sa.json service-account-prod.json application_default_credentials.json \
         .boto .s3cfg .docker/config.json innocent-state.log innocent-kube.log; do
  expect refuse "can hold credentials" "$W/$d"
done
for d in btmp wtmp lastlog auth.log auth.log.1 secure secure-20261101 BTMP; do   # login records need no fixture: the deny list runs first
  expect refuse "can hold credentials" "$L/$d"
done
expect ok app-line "$W/app.log"
expect ok train-line "$W/train.log"
expect ok nginx-line "$W/nginx/access.log"
if [ "$MODE" = bash ]; then expect ok syslog-line "$L/syslog"; expect ok nginx-var-line "$L/nginx/access.log"; fi
# WATERS-030: the resolved file is swapped for a symlink to /etc/os-release between the check and the open
expect refuse "changed after the check" "$W/results/race.log" "export PATH=$T/shim:\$PATH RACE_FLAG='$T/race.flag' RACE_TARGET='$W/results/race.log'"

# WATERS-036: a FIFO swapped in between the check and the open. The open must not block forever: refused
# within a few seconds, and (bash mode) nothing of ours left running.
MARK="logs-exec-$$-$RANDOM"
orphans() { local p c=0; for p in /proc/[0-9]*; do [ "$p" = "/proc/$$" ] && continue; { tr '\0' '\n' < "$p/environ"; } 2>/dev/null | grep -Fxq "LOGS_MARK=$MARK" && c=$((c + 1)); done; echo "$c"; }
t0=$SECONDS
expect refuse "not a regular file, or the open timed out" "$W/results/fifo.log" \
  "echo race-target > '$W/results/fifo.log'; export LOGS_MARK=$MARK BASH_ENV=$T/shim/hook.sh WS_LOGS_OPEN_TIMEOUT=2 FIFO_TARGET='$W/results/fifo.log' FIFO_FLAG='$T/fifo.flag'"
dt=$((SECONDS - t0)); n=$((n + 1))
if [ "$dt" -le 6 ]; then echo "ok - [$MODE] FIFO swap: refused in ${dt}s"; else echo "not ok - [$MODE] FIFO swap took ${dt}s"; fails=$((fails + 1)); fi
if [ "$MODE" = bash ]; then
  sleep 1; n=$((n + 1)); o="$(orphans)"
  if [ "$o" = 0 ]; then echo "ok - [bash] FIFO swap: no orphan bash/tail/sleep"; else echo "not ok - [bash] FIFO swap left $o processes"; fails=$((fails + 1)); fi
fi
# WATERS-036: swap between the open and the fd re-check (the opened file is renamed to a denied name)
expect refuse "changed after the check" "$W/race2.log" "export PATH=$T/shim:\$PATH RACE2_CNT='$T/race2.cnt' RACE2_FROM='$W/race2.log' RACE2_TO='$W/moved.tfstate'"

# --follow must not leave a tail behind once its parent (the ssh session) is gone
if [ "$MODE" = bash ] && [ -z "${LOGS_MUTATE:-}" ]; then
  n=$((n + 1))
  setup_cmd="$(setup)"
  bash -c "$setup_cmd" && : > "$W/results/follow.log"
  "$CLI" _logs-script "$W/results/follow.log" 5 1 "$ROOTS" > "$TMP/follow.sh"
  # shellcheck disable=SC2016  # $1 expands in the child shell
  setsid bash -c 'bash -s < "$1" >/dev/null 2>&1' _ "$TMP/follow.sh" &
  parent=$!
  sleep 1
  tails() { local c=0 p; for p in /proc/[0-9]*; do [ "$(cat "$p/comm" 2>/dev/null)" = tail ] && [ "$(readlink "$p/fd/0" 2>/dev/null)" = "$W/results/follow.log" ] && c=$((c + 1)); done; echo "$c"; }
  alive="$(tails)"
  kill -9 "$parent" 2>/dev/null; wait "$parent" 2>/dev/null
  gone=0; for _ in 1 2 3 4 5 6 7 8; do [ "$(tails)" = 0 ] && { gone=1; break; }; sleep 1; done
  if [ "$alive" -ge 1 ] && [ "$gone" = 1 ]; then echo "ok - [bash] follow: tail reads the fd, and exits with its parent (no orphan)"
  else echo "not ok - [bash] follow orphan check (alive=$alive gone=$gone)"; fails=$((fails + 1)); fi
fi

echo "logs-exec [$MODE${LOGS_MUTATE:+, mutate=$LOGS_MUTATE}]: $n cases, $fails failed"
[ "$fails" -eq 0 ]
