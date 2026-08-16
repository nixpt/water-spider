# Getting started

This guide takes a new installation through authentication and a first
cost-safe inspection. Creating a pod is deliberately a separate, explicit step.

## Prerequisites

For a local installation, place these commands on `PATH`:

- `runpodctl` for provider operations;
- `ssh` for connections, commands, GUI forwarding, and tunnels;
- `jq` for JSON parsing and safe GraphQL request construction;
- `pgrep` for tracked tunnel management;
- `curl` only when using GraphQL-only `create` flags.

Water-spider can optionally ask `bucket-bridge` to provision a missing
dependency when that fleet tool is already available. Standalone users should
install dependencies with their normal package manager.

## Install from source

```sh
git clone https://github.com/nixpt/water-spider.git
cd water-spider
export PATH="$PWD/bin:$PATH"
water-spider --help
```

Add the `bin` directory to your shell profile if you want the command available
in later sessions.

## Authenticate

The normal setup uses the configuration written by `runpodctl`:

```sh
runpodctl doctor
water-spider status
```

To scope an API key to one invocation instead of storing it in the RunPod
configuration, export `RUNPOD_API_KEY` only for that process. Fleet users can
also inject it through `secure-env`:

```sh
secure-env run --env RUNPOD_API_KEY -- water-spider status
```

Never paste API keys into commands that will be committed, issue descriptions,
or CI logs.

## Inspect before spending

These commands do not create a pod:

```sh
water-spider status
water-spider list
water-spider gpus --available
```

Confirm the account balance, current hourly spend, existing pod count, and an
appropriate GPU before proceeding.

## First lifecycle

Decide the maximum runtime, expected hourly price, and teardown time before the
create command. Give each experiment a stable, unique idempotency key.

```sh
water-spider create \
  --image IMAGE \
  --gpu "GPU NAME" \
  --idempotency-key first-water-spider-run

water-spider list
water-spider connect POD-ID
```

The create path performs one provider request and verifies the resulting pod.
If it returns an ambiguous failure, run `water-spider list`; do not simply run
create again with a different key.

When finished:

```sh
water-spider teardown POD-ID
water-spider list
```

Teardown asks for confirmation and then independently checks that the pod is
absent. Treat a failed absence check as an unknown/billable state that requires
immediate provider-console inspection.

## Docker CLI

```sh
docker pull nixpt/water-spider:latest
docker run --rm -it \
  -v "$HOME/.runpod:/root/.runpod:ro" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -p 8080:8080 \
  nixpt/water-spider status
```

The read-only mounts provide RunPod and SSH credentials without baking them
into the image. See the [Docker image guide](../docker/README.md) for control-pod
variants and build details.

## Next steps

- Learn every command in the [CLI reference](cli-reference.md).
- Set defaults using [configuration and state](configuration.md).
- Follow task-oriented examples in [common workflows](workflows.md).
