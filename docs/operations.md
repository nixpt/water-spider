# Operations

## Prerequisites

Install `runpodctl`, `jq`, `ssh`, and `pgrep`. GraphQL-only creation flags also
need `curl`. Authenticate with `runpodctl` so `~/.runpod/config.toml` exists, or
scope `RUNPOD_API_KEY` to the invocation. Keep SSH and registry credentials out
of logs and source control.

## Cost-safe lifecycle

```sh
water-spider status
water-spider gpus --available
water-spider create --image IMAGE --gpu "GPU NAME" \
  --idempotency-key SESSION-ID
water-spider connect POD-ID
water-spider tunnel POD-ID --port 8080:8080
# perform the work and pull every artifact worth keeping
water-spider teardown POD-ID
water-spider list
```

Before creation, set an explicit maximum runtime and expected cost. Use an
idempotency key whenever a human or automation may repeat a request. If create
returns an ambiguous error, inspect `water-spider list` before retrying.

Teardown is intentionally interactive. Pull results first, confirm the prompt,
and retain the final independent absence check in operational logs.

## Private images

`--registry-auth-id` is a GraphQL-only field and defaults from
`WATER_SPIDER_REGISTRY_AUTH_ID`. Use
[`docker/create-registry-auth.sh`](../docker/create-registry-auth.sh) to create
the RunPod registry record. Never commit the Docker Hub token or API key.

## Validation status

Recorded live evidence currently covers:

- pod creation and direct SSH;
- private-image pulls with registry authentication;
- GPU initialization and CUDA-backed llama.cpp inference;
- local SSH tunneling and a real HTTP completion through it;
- teardown followed by an independent list confirming absence.

Still awaiting focused live evidence under WATERS-003:

- a small `send`/`receive` round trip;
- `recipe serve` as the orchestrating command rather than equivalent manual
  server-plus-tunnel steps;
- GUI forwarding through xpra or raw X11;
- snapshot manifest collection from a live pod.

Do not infer those four workflows are live-proven from the mocked suite.
