#!/usr/bin/env bash
set -euo pipefail

repository="${DOCKERHUB_REPOSITORY:-nixpt/water-spider}"
description_file="${DOCKERHUB_DESCRIPTION_FILE:-docker/DOCKERHUB.md}"
short_description="${DOCKERHUB_SHORT_DESCRIPTION:-Cost-safe RunPod GPU lifecycle CLI and control-pod image family}"

: "${DOCKERHUB_USERNAME:?DOCKERHUB_USERNAME is required}"
: "${DOCKERHUB_PAT:?DOCKERHUB_PAT is required}"

if [[ ! -r "$description_file" ]]; then
  printf 'description file is not readable: %s\n' "$description_file" >&2
  exit 1
fi

namespace="${repository%%/*}"
name="${repository#*/}"
if [[ -z "$namespace" || -z "$name" || "$namespace" == "$name" ]]; then
  printf 'DOCKERHUB_REPOSITORY must use namespace/name format\n' >&2
  exit 1
fi

login_payload="$(jq -n \
  --arg username "$DOCKERHUB_USERNAME" \
  --arg password "$DOCKERHUB_PAT" \
  '{username: $username, password: $password}')"

token="$(curl --fail-with-body --silent --show-error \
  --request POST \
  --header 'Content-Type: application/json' \
  --data "$login_payload" \
  https://hub.docker.com/v2/users/login/ | jq -er '.token')"

update_payload="$(jq -n \
  --arg description "$short_description" \
  --rawfile full_description "$description_file" \
  '{description: $description, full_description: $full_description}')"

curl --fail-with-body --silent --show-error \
  --request PATCH \
  --header "Authorization: JWT $token" \
  --header 'Content-Type: application/json' \
  --data "$update_payload" \
  "https://hub.docker.com/v2/repositories/$namespace/$name/" \
  | jq -e '{name, namespace, description}'
