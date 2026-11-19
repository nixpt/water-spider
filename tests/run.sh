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
run_case "invalid pod id rejected" 1 "invalid pod id" "$CLI" get 'x"y'

printf '\n%d passed; %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
