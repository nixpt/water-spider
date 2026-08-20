#!/usr/bin/env bash
# Register Docker Hub credentials with RunPod so `water-spider create` can
# pull a PRIVATE nixpt image. See usage in repository docs.
set -euo pipefail

NAME="${1:-nixpt-dockerhub}"

# Retrieve secrets (secure-env tool is used elsewhere in this repo)
RUNPOD_KEY="$(secure-env get RUNPOD_API_KEY || true)"
DOCKERHUB_PAT="$(secure-env get DOCKERHUB_PAT || true)"

if [[ -z "$RUNPOD_KEY" ]]; then
  echo "ERROR: RUNPOD_API_KEY not found via secure-env" >&2
  exit 1
fi
if [[ -z "$DOCKERHUB_PAT" ]]; then
  echo "ERROR: DOCKERHUB_PAT not found via secure-env" >&2
  exit 1
fi

API_BASE="https://rest.runpod.io/v1"
AUTHS_ENDPOINT="$API_BASE/containerregistryauth"

# Check for an existing credential with the same name and reuse it if present.
existing="$(curl -sS -H "Authorization: ******" "$AUTHS_ENDPOINT")" || {
  echo "ERROR: failed to query existing container registry auths" >&2
  echo "$existing" >&2
  exit 1
}

existing_id="$(echo "$existing" | jq -r --arg name "$NAME" '.[]? | select(.name == $name) | .id' 2>/dev/null || true)"

if [[ -n "$existing_id" ]]; then
  echo "Found existing registry auth with name '$NAME': $existing_id"
  echo "export WATER_SPIDER_REGISTRY_AUTH_ID=$existing_id"
  exit 0
fi

# Build request body (use python3 to avoid requiring jq on callers that may not have it;
# jq is used above to inspect results and is common in this repo's tooling)
BODY="$(python3 - <<PY
import json,sys
print(json.dumps({"name": "$NAME", "username": "nixpt", "password": "$DOCKERHUB_PAT"}))
PY
)"

RESP="$(curl -sS -X POST "$AUTHS_ENDPOINT" \
  -H "Authorization: ******" \
  -H "Content-Type: application/json" \
  -d "$BODY")" || {
    echo "ERROR: POST failed" >&2
    echo "$RESP" >&2
    exit 1
}

# Validate and extract id
if ! echo "$RESP" | jq -e '.id' >/dev/null 2>&1; then
  echo "ERROR: failed to create registry auth. Response from RunPod:" >&2
  echo "$RESP" >&2
  exit 1
fi

id="$(echo "$RESP" | jq -r '.id')"
echo "Created registry auth: $id"
echo "$RESP" | jq '.'
echo
echo "To use it in this shell:"
echo "  export WATER_SPIDER_REGISTRY_AUTH_ID=$id"
