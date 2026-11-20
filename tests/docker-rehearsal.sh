#!/usr/bin/env bash
# Opt-in rehearsal of the REAL remote probe script inside a locked-down local
# container (no pod, no sshd). Pattern from neo's yantra rehearsal: run the
# script with bash directly in `docker run --rm --cap-drop ALL`. Verifies
# redaction, the no-nvidia-smi and no-ss degrade paths, and that the script
# writes nothing (read-only rootfs, no tmpfs). Usage: tests/docker-rehearsal.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/bin/water-spider"
IMG="${REHEARSAL_IMAGE:-ubuntu:22.04}"
docker image inspect "$IMG" >/dev/null 2>&1 || { echo "skip: image $IMG not present locally (no pull)"; exit 0; }
OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT
# A decoy workload with secrets on its cmdline, then the probe script on stdin.
"$CLI" _probe-script | docker run --rm -i --cap-drop ALL --security-opt no-new-privileges \
  --network none --read-only "$IMG" bash -c '
    ( exec -a "decoy --token hf_RehearsalSecret99 HF_TOKEN=hf_RehearsalSecret99 --password hunter2" sleep 30 ) &
    sleep 0.5
    bash -s; true' >"$OUT"
fail=0
chk() { if eval "$2"; then echo "ok - $1"; else echo "not ok - $1"; fail=1; fi; }
chk "end marker present" "grep -q '^@@WS:end@@' '$OUT'"
chk "nvidia-smi absent degrades" "awk '/^@@WS:gpu@@/{f=1;next}/^@@WS:/{f=0}f' '$OUT' | grep -qx ABSENT"
chk "no ss: falls back (netstat or proc)" "grep -Eq '^mode=(netstat|proc)' '$OUT'"
chk "decoy visible" "grep -q 'decoy' '$OUT'"
chk "no secret leaves the container" "! grep -Eq 'RehearsalSecret99|hunter2' '$OUT'"
chk "cgroup section present" "grep -q '^v=' '$OUT'"
"$CLI" ps --probe-file "$OUT" | head -30
exit "$fail"
