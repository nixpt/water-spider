#!/usr/bin/env bash
# Create/update the RunPod template for nixpt/water-spider:pod via the REST v1
# API. Same pattern as nixpt/zorro's docker/runpod/create-template.sh (REST,
# not GraphQL — introspection is disabled server-side so the schema can't be
# verified before use; REST returns templates in their true shape).
#
# This deploys a "control pod" variant (Dockerfile.runpod = CPU-only,
# Dockerfile.v2 = GPU + llama.cpp), NOT the lightweight one-shot CLI image
# (Dockerfile) — that one's ENTRYPOINT exits as soon as a subcommand
# finishes, which is the wrong shape for a Pod. Set TAG/CATEGORY/README/
# CONTAINER_DISK_GB/PORTS to switch which variant this publishes — see the
# v2 example in docker/README or the repo README's "RunPod control pod"
# section.
#
# PUBLISH_PUBLIC=1 sets isPublic:true — MUST be set at create time, not via a
# later PATCH: live-tested (2026-08-16) and confirmed a RunPod platform bug —
# ANY PATCH to a template that is (or would become) public fails with
# `"update template: public templates cannot have Registry Credentials"`,
# even for unrelated fields (rename tried, same error), even though the
# template's own containerRegistryAuthId reads back as "" the whole time.
# No workaround found short of "get isPublic right in the original POST" —
# if you need to change a public template later, delete + recreate.
set -euo pipefail

IMAGE="${IMAGE:-nixpt/water-spider}"
TAG="${TAG:-pod}"
NAME="${NAME:-water-spider-control-pod}"
CONTAINER_DISK_GB="${CONTAINER_DISK_GB:-10}"     # no model weights, no build artifacts —
                                                  # this pod just orchestrates OTHER pods
PORTS="${PORTS:-22/tcp}"                         # SSH only — water-spider has no HTTP
                                                  # service of its own; `tunnel`/`recipe`
                                                  # forward a target pod's port through
                                                  # THIS pod's own SSH session instead
PUBLISH_PUBLIC="${PUBLISH_PUBLIC:-0}"            # 1 = visible in RunPod's public template
                                                  # gallery to any RunPod user, not just you
CATEGORY="${CATEGORY:-CPU}"                      # CPU | NVIDIA | AMD (RunPod's own categories)
README="${README:-water-spider control pod — a small always-on CPU pod with water-spider (RunPod GPU-pod orchestration CLI) preinstalled on PATH. SSH in and run \`water-spider create/tunnel/recipe/teardown ...\` to manage your OTHER RunPod pods without keeping a laptop open. Not a GPU/inference image — see github.com/nixpt/water-spider for the CLI itself and the lightweight one-shot Docker image (nixpt/water-spider:latest) for local use instead.}"

API_KEY="$(secure-env get RUNPOD_API_KEY)"
[ -n "$API_KEY" ] || { echo "no RUNPOD_API_KEY in vault" >&2; exit 1; }

BODY=$(python3 -c '
import json,sys
img,name,disk,ports,is_public,category,readme = sys.argv[1:8]
print(json.dumps({
  "name": name, "imageName": img, "category": category,
  "containerDiskInGb": int(disk),
  "ports": [p for p in ports.split(",") if p],
  "isPublic": is_public == "1",
  "readme": readme,
}))' "$IMAGE:$TAG" "$NAME" "$CONTAINER_DISK_GB" "$PORTS" "$PUBLISH_PUBLIC" "$CATEGORY" "$README")

echo "==> creating template '$NAME' (public: $PUBLISH_PUBLIC)"
RESP=$(curl -sS -X POST "https://rest.runpod.io/v1/templates" \
     -H "Authorization: Bearer ${API_KEY}" -H 'Content-Type: application/json' -d "$BODY")
echo "$RESP" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(json.dumps({k:d[k] for k in ("id","name","imageName","ports","category","isPublic") if k in d}, indent=2) if isinstance(d,dict) else d)'
