#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/bin/water-spider"
MAYFLY_BRIDGE="$ROOT/integrations/mayfly-opencode/water-spider-mayfly"
TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

export HOME="$TEST_TMP/home"
export XDG_CACHE_HOME="$TEST_TMP/cache"
export PATH="$ROOT/tests/fakes:$PATH"
export RUNPOD_API_KEY=test-key
mkdir -p "$HOME/.ssh" "$XDG_CACHE_HOME"
: > "$HOME/.ssh/runpod"

passed=0
failed=0

pass() { printf 'ok - %s\n' "$1"; passed=$((passed + 1)); }
fail() { printf 'not ok - %s\n%s\n' "$1" "$2" >&2; failed=$((failed + 1)); }

run_case() {
  local name="$1" expected_rc="$2" pattern="$3"; shift 3
  local output rc=0
  output="$("$@" 2>&1)" || rc=$?
  if [ "$rc" -eq "$expected_rc" ] && printf '%s' "$output" | grep -Fq -- "$pattern"; then
    pass "$name"
  else
    fail "$name" "expected rc=$expected_rc and text: $pattern\nactual rc=$rc\n$output"
  fi
}

run_with_input() {
  local input="$1"; shift
  printf '%s\n' "$input" | "$@"
}

run_with_input_mode() {
  local input="$1" mode="$2"; shift 2
  printf '%s\n' "$input" | env FAKE_RUNPOD_MODE="$mode" "$@"
}

run_case "help" 0 "water-spider create" "$CLI" --help
run_case "list" 0 "pod-1" "$CLI" list
run_case "status" 0 "spend/hr NOW" "$CLI" status
run_case "get" 0 '"id": "pod-1"' "$CLI" get pod-1
run_case "connect parses ssh endpoint" 0 "ssh -p 22022" "$CLI" connect pod-1
run_case "send prints paired transfer" 0 "runpodctl send artifact.bin" "$CLI" send artifact.bin
run_case "receive prints destination" 0 "cd results" "$CLI" receive pod-1 /tmp/out results
run_case "tunnel records endpoint" 0 "http://localhost:8080" "$CLI" tunnel pod-tunnel
run_case "recipe list" 0 "Available recipes" "$CLI" recipe list
run_case "recipe serve" 0 "ready: http://localhost:9090" "$CLI" recipe serve pod-recipe /models/test.gguf --engine llama --port 9090
run_case "recipe serve for agents" 0 "engine=llama-agent" env FAKE_SSH_REQUIRE_AGENT=1 "$CLI" recipe serve pod-recipe /models/tool-model.gguf --engine llama-agent --port 9091
run_case "recipe agent launch propagates failure" 1 "remote launch failed" env FAKE_SSH_AGENT_FAIL=1 "$CLI" recipe serve pod-recipe /models/tool-model.gguf --engine llama-agent --port 9091
run_case "recipe rejects unknown engine" 1 "zorro|llama|llama-agent|pf" "$CLI" recipe serve pod-recipe /models/test.gguf --engine nope
run_case "Mayfly OpenCode bridge checks endpoint" 0 "OpenAI-compatible model catalog reached" "$MAYFLY_BRIDGE" check
run_case "gui x11" 0 "FAKE_SSH_OK" env DISPLAY=:0 "$CLI" gui pod-1 --x11 -- xterm
run_case "snapshot" 0 "wrote $TEST_TMP/snapshot.json" "$CLI" snapshot pod-1 -o "$TEST_TMP/snapshot.json"
run_case "teardown verifies deletion" 0 "confirmed gone" run_with_input_mode y empty-list "$CLI" teardown pod-1
run_case "gpu listing" 0 "NVIDIA RTX 4090" "$CLI" gpus --available
run_case "scaffold passthrough" 0 "FAKE_SCAFFOLD demo" "$CLI" scaffold demo
run_case "create" 0 "created pod pod-new" "$CLI" create --image example/image:latest --gpu "NVIDIA RTX 4090"
run_case "GraphQL create safely escapes strings" 0 "created pod pod-new" env RUNPOD_API_KEY=test FAKE_CURL_VALIDATE=1 "$CLI" create --image 'example/quoted"image' --name 'quoted"name' --gpu "NVIDIA RTX 4090" --min-download 100.5 --cuda-versions 12.4,12.5 --country US
run_case "GraphQL transport failure" 1 "GraphQL request failed" env RUNPOD_API_KEY=test FAKE_CURL_MODE=transport-fail "$CLI" create --image image --gpu gpu --min-download 100
run_case "GraphQL API error" 1 "GraphQL create failed: no capacity" env RUNPOD_API_KEY=test FAKE_CURL_MODE=graphql-error "$CLI" create --image image --gpu gpu --min-download 100
run_case "invalid numeric option" 1 "--min-download must be" env RUNPOD_API_KEY=test "$CLI" create --image image --gpu gpu --min-download nope
run_case "invalid CUDA list" 1 "invalid version" env RUNPOD_API_KEY=test "$CLI" create --image image --gpu gpu --cuda-versions 12.4,bad
run_case "invalid cloud enum" 1 "--cloud must be" "$CLI" create --image image --gpu gpu --cloud CHEAP
run_case "invalid country" 1 "--country must be" env RUNPOD_API_KEY=test "$CLI" create --image image --gpu gpu --country usa

run_case "malformed JSON fails visibly" 5 "jq: parse error" env FAKE_RUNPOD_MODE=malformed "$CLI" create --image example/image:latest --gpu gpu
run_case "API failure is surfaced" 1 "GraphQL request failed" env FAKE_RUNPOD_MODE=api-fail "$CLI" get pod-1
run_case "get of a missing pod fails" 1 "not found" env FAKE_RUNPOD_MODE=get-missing "$CLI" get pod-x
run_case "list via GraphQL shows GPU + cost" 0 "NVIDIA RTX 4090" "$CLI" list
run_case "list failure is an error, not empty" 1 "could not list pods" env FAKE_RUNPOD_MODE=list-fail "$CLI" list
run_case "list GraphQL error surfaced" 1 "GraphQL error: not authorized" env FAKE_RUNPOD_MODE=list-graphql-error "$CLI" list
run_case "list non-JSON response fails" 1 "non-JSON" env FAKE_RUNPOD_MODE=list-garbage "$CLI" list
run_case "status with no pods" 0 "nothing billing" env FAKE_RUNPOD_MODE=empty-list "$CLI" status
run_case "status with pods warns" 0 "2 pod(s) active" "$CLI" status
run_case "status list failure is not 'none'" 1 "could not list pods" env FAKE_RUNPOD_MODE=list-fail "$CLI" status
run_case "teardown still-listed is failure" 1 "STILL LISTED" run_with_input_mode y ok "$CLI" teardown pod-1
run_case "teardown terminate error then still listed" 1 "STILL LISTED" run_with_input_mode y terminate-fail "$CLI" teardown pod-1
run_case "teardown verify query fails => UNKNOWN" 1 "UNKNOWN" run_with_input_mode y list-fail "$CLI" teardown pod-1
run_case "teardown unparseable verify => UNKNOWN" 1 "UNKNOWN" run_with_input_mode y list-garbage "$CLI" teardown pod-1
run_case "create refuses when listing fails" 1 "refusing to create" env FAKE_RUNPOD_MODE=list-fail "$CLI" create --image example/image:latest --gpu gpu
run_case "create refuses on listing GraphQL error" 1 "refusing to create" env FAKE_RUNPOD_MODE=list-graphql-error "$CLI" create --image example/image:latest --gpu gpu
run_case "GraphQL-path create refuses when listing fails" 1 "refusing to create" env FAKE_RUNPOD_MODE=list-fail "$CLI" create --image image --gpu gpu --country US
run_case "old runpodctl refuses default create" 1 "needs runpodctl >= 3.1.1" env FAKE_RUNPOD_VERSION=2.1.9 "$CLI" create --image example/image:latest --gpu gpu
run_case "ambiguous SSH data refuses tunnel" 1 "could not resolve pod host/port" env FAKE_RUNPOD_MODE=ambiguous-ssh "$CLI" tunnel unknown

idem_key="same-key"
run_case "first idempotent create" 0 "created pod pod-new" "$CLI" create --image example/image:latest --gpu gpu --idempotency-key "$idem_key"
run_case "duplicate idempotency key replays" 0 "idempotent replay" "$CLI" create --image example/image:latest --gpu gpu --idempotency-key "$idem_key"
run_case "failed teardown verification is not success" 1 "could not verify" run_with_input_mode y list-fail "$CLI" teardown pod-1

# idempotency ledger replay must fail closed too
run_case "ledger replay refuses when listing fails" 1 "refusing to create" env FAKE_RUNPOD_MODE=list-fail "$CLI" create --image example/image:latest --gpu gpu --idempotency-key "$idem_key"

# teardown must really send podTerminate, and the REST CLI must not be used
CURL_LOG="$TEST_TMP/curl.log"; : > "$CURL_LOG"
run_case "teardown terminates via GraphQL then verifies" 0 "confirmed gone" run_with_input_mode y empty-list env FAKE_CURL_LOG="$CURL_LOG" "$CLI" teardown pod-1
if grep -q 'podTerminate' "$CURL_LOG" && grep -q 'podId: "pod-1"' "$CURL_LOG" && [ "$(grep -c myself "$CURL_LOG")" -ge 1 ]; then pass "teardown issued podTerminate + a fresh listing"; else fail "teardown issued podTerminate + a fresh listing" "$(cat "$CURL_LOG")"; fi
# API key must not appear on curl's argv; the fake exits 99 if it does, so the
# GraphQL cases above (list/create) passing proves it. Check the guard itself works:
run_case "fake curl rejects Bearer on argv (guard self-test)" 99 "Bearer token found on argv" curl -H "Authorization: Bearer x" https://example.invalid
run_case "GraphQL create passes key via stdin, not argv" 0 "created pod pod-new" "$CLI" create --image image --gpu gpu --country US
run_case "invalid pod id rejected" 1 "invalid pod id" "$CLI" get 'x"y'

# --- pod visibility (WATERS-027) ---
export XDG_RUNTIME_DIR="$TEST_TMP/run"; mkdir -p "$XDG_RUNTIME_DIR"
SSHLOG="$TEST_TMP/ssh.log"; : > "$SSHLOG"
run_case "ps explicit host needs no RunPod API" 0 "pod 10.0.0.1:2222" env FAKE_RUNPOD_MODE=api-fail FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-risky.txt" "$CLI" ps --host 10.0.0.1 --pod-port 2222
run_case "ps shows user pid vram and redacted cmdline" 0 "python3 serve.py --token <redacted> HF_TOKEN=<redacted>" env FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-risky.txt" "$CLI" ps --host 10.0.0.1 --pod-port 2222
PSOUT="$(env FAKE_SSH_LOG="$SSHLOG" FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-risky.txt" "$CLI" ps --host 10.0.0.1 --pod-port 2222 2>&1)"
for secret in abc123supersecret hf_AbCdEf0123456789 sk-live1234567890abcd; do
  if printf '%s' "$PSOUT" | grep -Fq "$secret"; then fail "ps output hides $secret" "$PSOUT"; else pass "ps output hides $secret"; fi
done
run_case "ps flags public non-sshd listener" 0 "PUBLIC listener 0.0.0.0:8888 owned by jupyter" printf '%s' "$PSOUT"
run_case "ps flags ipv6 public listener" 0 "PUBLIC listener [::]:9999" printf '%s' "$PSOUT"
if printf '%s' "$PSOUT" | grep -q 'PUBLIC listener 0.0.0.0:22 '; then fail "ps does not flag sshd" "$PSOUT"; else pass "ps does not flag sshd"; fi
run_case "ps shows loopback listener" 0 "LOOPBACK  127.0.0.1" printf '%s' "$PSOUT"
run_case "ps flags unidentifiable GPU process" 0 "pid 777 (ghost" printf '%s' "$PSOUT"
run_case "ps flags orphaned GPU process" 0 "pid 4242 (python3) is reparented to pid" printf '%s' "$PSOUT"
run_case "ps flags disk > 90%" 0 "disk / is 95% full" printf '%s' "$PSOUT"
run_case "ps flags VRAM > 95%" 0 "VRAM on GPU0 is 23900/24564 MiB" printf '%s' "$PSOUT"
run_case "ps shows cgroup mem and cpu, not host" 0 "mem 20.0 GiB / 64.0 GiB (31%)   cpu limit 16.0 vCPU" printf '%s' "$PSOUT"
run_case "ps clean pod has no flags" 0 "ok: no risk flags" env FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-clean.txt" "$CLI" ps --host 10.0.0.1 --pod-port 2222
run_case "gpu summary and per-process VRAM" 0 "4242     root       23800" env FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-risky.txt" "$CLI" gpu --host 10.0.0.1 --pod-port 2222
run_case "gpu summary line" 0 "util 91%  VRAM 23900/24564 MiB  pwr 410.20/450.00 W  temp 71C  SM 2520 MHz  mem 10501 MHz" env FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-risky.txt" "$CLI" gpu --host 10.0.0.1 --pod-port 2222
run_case "gpu also flags public listeners" 0 "PUBLIC listener 0.0.0.0:8888 owned by jupyter" env FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-risky.txt" "$CLI" gpu --host 10.0.0.1 --pod-port 2222
run_case "gpu --watch below 5 refused" 1 "N >= 5" "$CLI" gpu --host 10.0.0.1 --pod-port 2222 --watch 4
run_case "gpu --watch runs bounded ticks" 0 "refresh every 5s" env WATER_SPIDER_WATCH_MAX_TICKS=2 FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-clean.txt" "$CLI" gpu --host 10.0.0.1 --pod-port 2222 --watch 5
run_case "ps resolves a bare pod id like connect" 0 "pod pod-1" env FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-clean.txt" "$CLI" ps pod-1
run_case "ps rejects option-injection host" 1 "invalid --host" env FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-clean.txt" "$CLI" ps --host -oProxyCommand=x --pod-port 22
run_case "ps ssh failure is an error with redacted stderr" 1 "token=<redacted>" env FAKE_SSH_PROBE_FAIL=1 FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-clean.txt" "$CLI" ps --host 10.0.0.1 --pod-port 2222

# redaction fuzz: every secret must vanish, and a second pass must change nothing
RED_PROG="$("$CLI" _redact-prog)"
RED_CASES=(
  'run --token abc123XYZ end' 'run --token -x1secretval end' 'a --token "multi word secret" b' "PGPASSWORD='a b secret' psql"
  'curl -H X-Api-Key: s3cr3tvalue1 x' 'curl -H Authorization: Token tok3nvalue99 x' 'curl -u admin:s3cr3tpass x' 'tool --user bob:s3cr3tpass x'
  'git clone https://ghtoken1234@github.com/x' 'git clone https://u:p@ss@github.com/x' 'x --password s3cr3tpw' 'x --pass s3cr3tpw' 'x --passphrase s3cr3tpw'
  'x --cookie s3cr3tcookie' 'x --jwt s3cr3tjwt' 'x --session-id s3cr3tsid' 'x -p s3cr3tpw' 'x HF_TOKEN=hf_AbCdEf0123456789'
  'x Authorization: Bearer abcdefghijklmnop' 'x 0123456789abcdef0123456789abcdef01234567 y' 'x sk-live1234567890abcd' 'x rp_ABCDEFGH1234'
)
RED_SECRETS=(abc123XYZ x1secretval "multi word" "a b secret" s3cr3tvalue1 tok3nvalue99 s3cr3tpass ghtoken1234 "p@ss" s3cr3tpw s3cr3tcookie s3cr3tjwt s3cr3tsid hf_AbCdEf abcdefghijklmnop 0123456789abcdef0123456789abcdef01234567 sk-live123 rp_ABCDEFGH)
red_leak=""; red_idem=""
for c in "${RED_CASES[@]}"; do
  o1="$(printf '%s\n' "$c" | sed -E -e "$RED_PROG")"; o2="$(printf '%s\n' "$o1" | sed -E -e "$RED_PROG")"
  for sec in "${RED_SECRETS[@]}"; do case "$c" in *"$sec"*) case "$o1" in *"$sec"*) red_leak="$red_leak [$c => $o1]";; esac;; esac; done
  [ "$o1" = "$o2" ] || red_idem="$red_idem [$o1 => $o2]"
done
if [ -z "$red_leak" ]; then pass "redaction fuzz: no secret survives"; else fail "redaction fuzz: no secret survives" "$red_leak"; fi
if [ -z "$red_idem" ]; then pass "redaction is idempotent"; else fail "redaction is idempotent" "$red_idem"; fi
export RED_PROG
run_case "redaction keeps ordinary flags" 0 "-p 8080 --model x.gguf" bash -c "printf '%s\n' 'srv -p 8080 --model x.gguf' | sed -E -e \"\$RED_PROG\""
run_case "broken ControlMaster dir fails closed" 1 "cannot create ControlMaster dir" env XDG_RUNTIME_DIR=/proc FAKE_SSH_PROBE_FILE="$ROOT/tests/fixtures/probe-clean.txt" "$CLI" ps --host 10.0.0.1 --pod-port 2222
run_case "bad pod id refused before API call" 1 "invalid pod id" "$CLI" ps 'a;b'
run_case "bad port refused" 1 "invalid --pod-port" "$CLI" ps --host 10.0.0.1 --pod-port 70000
# many processes + small --limit: head closes the pipe early (SIGPIPE under pipefail must not abort)
BIG="$TEST_TMP/probe-big.txt"
awk '/^@@WS:ps@@/{print; for(i=0;i<3000;i++) printf "root %d 1 100 0.%d 1024 /usr/bin/worker --id %d\n", 1000+i, i%10, i; skip=1; next} /^@@WS:/{skip=0} !skip' "$ROOT/tests/fixtures/probe-clean.txt" > "$BIG"
run_case "ps with thousands of procs and --limit 2 survives SIGPIPE" 0 "3000 total, top 2" env FAKE_SSH_PROBE_FILE="$BIG" "$CLI" ps --host 10.0.0.1 --pod-port 2222 --limit 2
# the single ssh call: stdin script, ControlMaster, BatchMode, one round trip
nssh="$(grep -c '^ARGV:' "$SSHLOG")"
if [ "$nssh" -eq 1 ]; then pass "ps makes exactly one ssh call"; else fail "ps makes exactly one ssh call" "got $nssh"; fi
for opt in "bash -s" "BatchMode=yes" "ControlMaster=auto" "ControlPersist=60" "ConnectTimeout=" "ControlPath=$XDG_RUNTIME_DIR/water-spider-cm/"; do
  if grep -Fq -- "$opt" "$SSHLOG"; then pass "ssh uses $opt"; else fail "ssh uses $opt" "$(grep ARGV "$SSHLOG")"; fi
done
if [ "$(stat -c %a "$XDG_RUNTIME_DIR/water-spider-cm")" = 700 ]; then pass "ControlMaster dir is 0700"; else fail "ControlMaster dir is 0700" ""; fi
# the remote script is read-only
SCRIPT="$("$CLI" _probe-script)"
BODY="$(printf '%s\n' "$SCRIPT" | sed '1d' | sed -E 's#2?>/dev/null##g; s#2>&1##g; s#</dev/null##g')"
RO_RE='(^|[^A-Za-z_-])(kill|pkill|rm|mv|cp|tee|mkdir|touch|chmod|apt|apt-get|pip|curl|wget|mktemp|dd)[[:space:]]|environ|<<|>[[:space:]]*[^&[:space:]]'
if printf '%s' "$BODY" | grep -Eq "$RO_RE"; then fail "remote script is read-only" "$(printf '%s' "$BODY" | grep -En "$RO_RE" | head)"
else pass "remote script is read-only (no kill/write/install/environ/heredoc)"; fi
# degrade paths: run the REAL remote script with fakes; no nvidia-smi, no ss, no netstat
FB="$TEST_TMP/fakebin"; mkdir -p "$FB"
for t in bash cat awk sed date hostname id df printf head tr wc read; do p="$(command -v "$t" 2>/dev/null || true)"; [ -n "$p" ] && ln -sf "$p" "$FB/$t"; done
cat > "$FB/ps" <<'PSF'
#!/bin/sh
echo "root 11 1 50 0.5 2048 python run.py --api-key=sk-ABCDEFGH12345678 password=hunter2 rp_ABCDEFGH1234"
PSF
chmod +x "$FB/ps"
DEG="$(PATH="$FB" "$FB/bash" -c "$SCRIPT" 2>&1 </dev/null || true)"
run_case "no nvidia-smi degrades" 0 "ABSENT" printf '%s' "$DEG"
run_case "no ss/netstat degrades to /proc/net/tcp" 0 "mode=proc" printf '%s' "$DEG"
run_case "remote side redacts before output leaves" 0 "--api-key=<redacted> password=<redacted> <redacted>" printf '%s' "$DEG"
if printf '%s' "$DEG" | grep -Eq 'sk-ABCDEFGH|hunter2|rp_ABCDEFGH'; then fail "remote output has no secrets" "$DEG"; else pass "remote output has no secrets"; fi
printf '%s' "$DEG" > "$TEST_TMP/deg.txt"
run_case "ps renders degraded probe" 0 "gpu: nvidia-smi absent" "$CLI" ps --probe-file "$TEST_TMP/deg.txt"

# opt-in: real remote script inside a locked-down local container
if [ "${WS_TEST_DOCKER:-0}" = 1 ]; then run_case "docker rehearsal of the remote probe" 0 "no secret leaves the container" "$ROOT/tests/docker-rehearsal.sh"; fi

printf '\n%d passed; %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
