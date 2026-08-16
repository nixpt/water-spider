#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/bin/water-spider"
TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

export HOME="$TEST_TMP/home"
export XDG_CACHE_HOME="$TEST_TMP/cache"
export PATH="$ROOT/tests/fakes:$PATH"
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
run_case "API failure is surfaced" 1 "runpodctl pod get pod-1 failed" env FAKE_RUNPOD_MODE=api-fail "$CLI" get pod-1
run_case "ambiguous SSH data refuses tunnel" 1 "could not resolve pod host/port" env FAKE_RUNPOD_MODE=ambiguous-ssh "$CLI" tunnel unknown

idem_key="same-key"
run_case "first idempotent create" 0 "created pod pod-new" "$CLI" create --image example/image:latest --gpu gpu --idempotency-key "$idem_key"
run_case "duplicate idempotency key replays" 0 "idempotent replay" "$CLI" create --image example/image:latest --gpu gpu --idempotency-key "$idem_key"
run_case "failed teardown verification is not success" 1 "could not verify" run_with_input_mode y list-fail "$CLI" teardown pod-1

printf '\n%d passed; %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
