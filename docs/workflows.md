# Common workflows and troubleshooting

These examples use placeholders intentionally. Confirm pricing and choose a
hard teardown time before substituting real values.

## Safe create, work, and teardown

```sh
water-spider status
water-spider gpus --available
water-spider create --image IMAGE --gpu "GPU NAME" \
  --idempotency-key SESSION-ID
water-spider connect POD-ID

# Do the work, then preserve results before deletion.
water-spider teardown POD-ID --pull /workspace/results
water-spider list
```

Reuse the same idempotency key if the caller repeats the same logical request.
Never change the key merely because the first response was ambiguous.

## Serve a model locally from a remote GPU

```sh
water-spider recipe list
water-spider recipe serve POD-ID /workspace/models/model.gguf \
  --engine llama --port 8080
curl http://localhost:8080/health
```

The service runs on the pod while the local URL reaches it through SSH. Stop
the tracked tunnel without deleting the pod using:

```sh
water-spider tunnel POD-ID --stop
```

## Manual service tunnel

For a service already running on remote port 8080:

```sh
water-spider tunnel POD-ID --port 9000:8080
curl http://localhost:9000/
```

This needs SSH access only; it does not require exposing an additional RunPod
public port.

## Move small artifacts

```sh
water-spider send ./prompt-suite.json
water-spider receive POD-ID /workspace/results ./results
```

The provider's paired transfer is suitable for small artifacts. Large model or
disk transfers over the pod-to-home path can be slow; reacquire models from
their source or use RunPod network volumes instead.

## Recreate from a manifest

```sh
water-spider snapshot POD-ID -o experiment.snapshot.json
water-spider teardown POD-ID
water-spider create --image IMAGE --restore experiment.snapshot.json \
  --gpu "GPU NAME" --idempotency-key experiment-restore-01
```

The manifest replays model acquisition and checks provenance. It is not a
byte-for-byte backup.

## Private image creation

Create a RunPod registry credential once, then use its ID:

```sh
bash docker/create-registry-auth.sh
export WATER_SPIDER_REGISTRY_AUTH_ID=REGISTRY-AUTH-ID
water-spider create --image PRIVATE-IMAGE --gpu "GPU NAME" \
  --idempotency-key private-image-01
```

This path uses GraphQL and requires `curl`.

## Troubleshooting

### Create returned an error and pod state is unclear

Run `water-spider list` and inspect the provider console. If the pod exists,
record its ID and continue or tear it down. Retry only after proving absence,
and reuse the original idempotency key.

### SSH data is missing or ambiguous

Run `water-spider get POD-ID` and wait for the pod to become ready. Do not copy
an endpoint from a different pod. `connect` deliberately refuses ambiguous
provider data.

### A local tunnel is stale

```sh
water-spider tunnel POD-ID --stop
water-spider tunnel POD-ID --port LOCAL:REMOTE
```

If the SSH process died independently, the stale state is detected. Check that
the pod service is listening on the remote port before recreating the tunnel.

### Teardown could not verify deletion

Assume the resource may still be billable. Check `water-spider list` and the
RunPod console immediately. Do not interpret a successful delete request as
proof until the pod is absent from a fresh query.

### A command is missing a dependency

Compare the command with the prerequisite list in
[getting started](getting-started.md). Only GraphQL creation needs `curl`; GUI
and model-serving features also depend on software inside the selected pod
image.

## Evidence boundary

Deterministic tests cover every dispatch path with fakes, but mocks do not prove
provider behavior. See [operations](operations.md) for the exact live-validated
and not-yet-live-validated workflows.
