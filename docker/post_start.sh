#!/bin/bash
# post_start.sh — RunPod's own /start.sh (base image runpod/base:*) executes this
# automatically via its `execute_script "/post_start.sh"` hook, AFTER its own setup_ssh/
# export_env_vars have run. This is the SUPPORTED extension point — do not override
# ENTRYPOINT/CMD instead (overriding the base's own startup stops it running sshd/
# key-injection at all, which is worse than anything this script defends against).
#
# Ported verbatim (minus a zorro-specific PATH step) from nixpt/zorro's docker/
# post_start.sh — this logic is generic to any runpod/base-family image, not
# specific to zorro's CUDA image. See that repo's version for the incident history
# (POD-0811, s429/runpod-next) this defends against: `/start.sh`'s setup_ssh() is
# entirely gated on $PUBLIC_KEY being non-empty at the moment start.sh runs — if
# RunPod's platform doesn't land that env var in time, or `service ssh start` fails
# silently, NOTHING recovers it. This script re-derives that logic verbatim and
# re-runs it unconditionally, idempotently, checking real state rather than trusting
# that the base's own pass succeeded. Every step is safe to run twice.
set -u

log() { echo "[post_start.sh] $*"; }

# --- 1. SSH key: install if $PUBLIC_KEY is visible here even if setup_ssh missed it,
#        and DEDUPE (a naive `>>` on every boot would grow authorized_keys unboundedly
#        across pod restarts on a persistent volume). ---
if [[ -n "${PUBLIC_KEY:-}" ]]; then
    mkdir -p ~/.ssh
    touch ~/.ssh/authorized_keys
    if ! grep -qxF "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        log "installed PUBLIC_KEY into authorized_keys (was missing)"
    fi
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
else
    log "WARNING: \$PUBLIC_KEY is empty in this script's environment too — if direct SSH" \
        "still fails after this, the key genuinely never reached the container from" \
        "RunPod's side. Use the proxy SSH (ssh.runpod.io) to add a key by hand:" \
        "  mkdir -p ~/.ssh && echo '<your-pubkey>' >> ~/.ssh/authorized_keys"
fi

# --- 2. Host keys: generate any that are missing (this is what "no hostkeys available --
#        exiting" in POD-0811's incident meant — setup_ssh() never got this far). ---
for kind_path in "rsa /etc/ssh/ssh_host_rsa_key" "dsa /etc/ssh/ssh_host_dsa_key" \
                  "ecdsa /etc/ssh/ssh_host_ecdsa_key" "ed25519 /etc/ssh/ssh_host_ed25519_key"; do
    kind="${kind_path%% *}"; path="${kind_path#* }"
    if [[ ! -f "$path" ]]; then
        ssh-keygen -t "$kind" -f "$path" -q -N '' && log "generated missing $kind host key"
    fi
done

# --- 3. sshd itself: verify it is actually LISTENING, not just that `service ssh start`
#        exited 0 (a service unit can report started while the daemon exits immediately —
#        exactly the "no hostkeys available -- exiting" failure mode). ---
mkdir -p /run/sshd
if ! ss -ltn 2>/dev/null | grep -q ':22 '; then
    log "sshd not listening on :22 after the base's own setup — starting it directly"
    service ssh start >/dev/null 2>&1 || /usr/sbin/sshd
    sleep 1
    if ss -ltn 2>/dev/null | grep -q ':22 '; then
        log "sshd now listening — self-heal worked"
    else
        log "ERROR: sshd STILL not listening after direct start attempt — this needs a" \
            "human to look at sshd's own error output (\`/usr/sbin/sshd -D -e\` in the" \
            "foreground will show it), not another automated retry"
    fi
else
    log "sshd already listening on :22 — base image's own setup_ssh succeeded, nothing to fix"
fi

log "done — direct SSH should now work: ssh root@<pod-ip> -p <mapped-22-port>"
log "water-spider is on PATH — use this pod as a persistent 'control pod' to manage" \
    "other RunPod pods without keeping a laptop open (create/tunnel/recipe/teardown, etc)"
