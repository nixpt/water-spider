#!/usr/bin/env bash
# Register Docker Hub credentials with RunPod so `water-spider create` can
# pull a PRIVATE nixpt image (nixpt/zorro has been private since 2026-08-16).
# `runpodctl create pod --help` has NO flag for this at all — checked
# directly, not assumed — so this, like minDownload/allowedCudaVersions,
# only exists via the REST/GraphQL API, never via the CLI.
#
# Usage:
#   docker/create-registry-auth.sh
#   export WATER_SPIDER_REGISTRY_AUTH_ID=<id from the output>
#   water-spider create --image nixpt/zorro:v3 --gpu "..." ...   # now just works
#
# Live-tested end to end (2026-08-16): ran this, created a real pod with
# --registry-auth-id set to the resulting id, confirmed via SSH that the
# pod actually pulled the (by-then-private) image and `zorro --version`
# ran — not just that the RunPod API accepted the field syntactically.
# Current live id: cmsvny408000t1p6ujkm1o1uc (name "nixpt-dockerhub").
#
# NOT idempotent — RunPod's `name` field must be unique per account; running
# this twice with the same name fails rather than replacing. Check existing
# creds first: GET https://rest.runpod.io/v1/containerregistryauth
set -euo pipefail
NAME="${1:-nixpt-dockerhub}"
RUNPOD_KEY="$(secure-env get RUNPOD_API_KEY)"
DOCKERHUB_PAT="$(secure-env get DOCKERHUB_PAT)"
BODY="$(python3 -c "
import json,sys
print(json.dumps({'name': sys.argv[1], 'username': 'nixpt', 'password': sys.argv[2]}))
" "$NAME" "$DOCKERHUB_PAT")"
curl -sS -X POST "https://rest.runpod.io/v1/containerregistryauth" \
  -H "Authorization: Bearer ${RUNPOD_KEY}" -H 'Content-Type: application/json' \
  -d "$BODY"
echo
