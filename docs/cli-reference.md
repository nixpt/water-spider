# CLI reference

Run `water-spider --help` for the compact built-in synopsis. This page adds
behavior, side effects, and examples.

## Provisioning and inspection

### `create`

```text
water-spider create [--template-id ID] [--image IMAGE] [--name NAME]
  [--gpu "GPU NAME"] [--gpu-count N] [--ports SPEC]
  [--disk GB] [--volume GB] [--cloud SECURE|COMMUNITY]
  [--restore FILE] [--idempotency-key KEY]
  [--min-download MBPS] [--min-upload MBPS]
  [--cuda-versions "12.4,12.5"] [--data-center ID] [--country CC]
  [--registry-auth-id ID]
```

Creates once, verifies by listing pods, and prints the pod ID. Use
`--idempotency-key` for retry-safe callers. Bandwidth, CUDA, location, and
registry-auth flags select the GraphQL transport; other requests use
`runpodctl`. Numeric and enumerated inputs are validated before contacting the
provider.

`--restore` accepts a manifest produced by `snapshot`; it does not restore a
disk image.

### `list`, `status`, and `get`

```sh
water-spider list
water-spider status
water-spider get POD-ID
```

`list` shows pods. `status` summarizes balance, current spend per hour, and pod
count. `get` returns one pod's provider record.

### `gpus`

```sh
water-spider gpus
water-spider gpus --available
```

Lists RunPod GPU types; `--available` filters to currently available entries.

## Connections and services

### `connect`

```sh
water-spider connect POD-ID
```

Resolves SSH data and prints a direct command, with a proxy fallback when
needed. Ambiguous SSH records fail instead of choosing an arbitrary endpoint.

### `tunnel`

```sh
water-spider tunnel POD-ID
water-spider tunnel POD-ID --port 9000:8080 --port 11450:11450
water-spider tunnel POD-ID --stop
```

Starts tracked SSH local forwards. Defaults are local/remote port 8080 and
11450. Custom mappings use `LOCAL:REMOTE`. Only the tunnel PID recorded for the
pod is stopped.

### `recipe`

```sh
water-spider recipe list
water-spider recipe serve POD-ID MODEL-PATH [--engine zorro|llama|pf] [--port N]
```

`recipe serve` launches the selected pod-side model server, creates a local
tunnel, and prints the local URL. Engine availability depends on the pod image.

### `gui`

```sh
water-spider gui POD-ID [--x11|--trusted] [--display N] [--] COMMAND [ARGS...]
```

Runs a remote GUI application locally. It prefers xpra when available and falls
back to SSH X11 forwarding. `--x11` forces raw X11; `--trusted` uses trusted X11
forwarding. The pod needs the corresponding X11/xpra support.

The `v2` image includes `xauth`, not arbitrary desktop applications. See the
[v2 GPU and GUI guide](v2-gpu-guide.md) for local display prerequisites,
installing a pod-side application, security boundaries, and examples.

## Files and preservation

### `send` and `receive`

```sh
water-spider send LOCAL-PATH
water-spider receive POD-ID REMOTE-PATH [LOCAL-DESTINATION]
```

These wrap the paired `runpodctl` transfer flow. `send` prints the command/code
needed on the receiving pod; `receive` pulls a remote path to the selected local
destination.

### `snapshot`

```sh
water-spider snapshot POD-ID [-o FILE]
```

Writes a lightweight model and image-provenance manifest. It intentionally does
not copy the pod filesystem.

### `teardown`

```sh
water-spider teardown POD-ID [--session-name NAME] [--pull PATH ...]
```

Optionally pulls named paths, prompts before deletion, stops the tracked tunnel,
deletes the pod, and confirms absence with a fresh list. A failed verification
is reported as failure even if the provider's delete command returned success.

## Optional fleet integration

```sh
water-spider scaffold NAME [foreman-scaffold flags ...]
```

This is a thin passthrough to a sibling `jokersquad` checkout's
`foreman-scaffold`. It is optional, fleet-internal, and has no effect on the
standalone commands above.

## Exit behavior

Commands write normal results to stdout and diagnostics to stderr. Invalid
arguments, missing dependencies, provider/API errors, ambiguous data, and
failed safety verification return non-zero. Automation should branch on the
exit status and inspect provider state before retrying any billable action.

See [configuration and local state](configuration.md) for defaults and
credentials.
