---
name: water-spider
description: Operate and troubleshoot RunPod GPU pod lifecycles through the water-spider CLI with strict cost-safety, idempotency, credential, artifact-preservation, and teardown-verification guardrails. Use when an agent needs to inspect RunPod account or pod state; choose GPUs; create, connect to, tunnel into, transfer files to or from, snapshot, serve models on, or tear down pods; work with water-spider Docker/control-pod images; diagnose water-spider failures; or modify and test the water-spider project.
---

# Water Spider

Use the repository's `bin/water-spider` as the authority for RunPod lifecycle
behavior. Preserve the evidence boundary between deterministic tests and live
provider verification.

## Locate the project and read the right guide

From anywhere inside the checkout, resolve the repository root with:

```sh
repo_root="$(git rev-parse --show-toplevel)"
```

Otherwise, locate a checkout containing both `bin/water-spider` and
`docs/cli-reference.md`. Do not assume a globally installed command is the same
revision as the checkout being changed.

Read only the references needed for the task:

- Read `docs/cli-reference.md` for command syntax and side effects.
- Read `docs/getting-started.md` for installation or first-use requests.
- Read `docs/configuration.md` for credentials, defaults, private registries,
  idempotency state, tunnels, or snapshot manifests.
- Read `docs/workflows.md` for task sequences and failure recovery.
- Read `docs/operations.md` before any live or billable operation.
- Read `docs/testing.md` before changing code or making verification claims.
- Read `docker/README.md` for `latest`, `pod`, `v2`, image builds, or RunPod
  templates.

## Classify the requested action

Choose one class before invoking the CLI:

1. **Read-only:** `status`, `list`, `get`, `gpus`, help, local documentation,
   and non-mutating diagnostics. Run these when relevant without requiring a
   cost cap.
2. **Local/reversible:** start or stop a local tunnel, print transfer commands,
   or run deterministic tests. Confirm exact pod IDs and paths first.
3. **Billable:** `create`, restoring onto a new pod, or any action that keeps a
   paid resource running. Require explicit user authorization, a maximum cost
   or runtime, and a teardown deadline. A general request to inspect or explain
   does not authorize creation.
4. **Destructive:** `teardown` or replacing a public RunPod template. Resolve
   the exact target and preserve requested artifacts before acting. A direct
   request to stop/delete a named pod authorizes teardown of that pod.

Never broaden one class into another implicitly.

## Inspect before mutation

For a live task, begin with the cheapest relevant state checks:

```sh
bin/water-spider status
bin/water-spider list
bin/water-spider gpus --available
```

Before creation, report the selected image or template, GPU, count, storage,
cloud/location constraints, stable idempotency key, cost/runtime cap, and
teardown deadline. If any cost boundary is missing, stop before the create call
and request it.

Keep `RUNPOD_API_KEY`, Docker tokens, SSH keys, and registry credentials out of
commands shown to users, logs, tickets, and commits. Prefer existing
`runpodctl` configuration or scoped secret injection.

## Create exactly once

Use a stable idempotency key for every repeatable request:

```sh
bin/water-spider create --image IMAGE --gpu "GPU NAME" \
  --idempotency-key SESSION-ID
```

Do not wrap create in a retry loop. Do not invent a new key after a timeout or
ambiguous response. Run `list`, inspect provider state, and reuse the original
key only after understanding the result.

GraphQL-only bandwidth, CUDA, location, country, and registry-auth constraints
require `curl`. Validate the documented option shape before contacting RunPod.

## Operate and preserve work

Use `connect` to resolve SSH rather than guessing endpoints. Use `tunnel` for
local access to a remote service and `recipe serve` when the image contains the
requested engine. Confirm engine and model availability before launching.

Treat provider file transfer as appropriate for small artifacts. Prefer source
re-downloads or network volumes for large models. `snapshot` creates a model
and provenance manifest, not a disk backup.

Before teardown:

1. Identify the exact pod ID and purpose.
2. Pull every requested or irreplaceable artifact.
3. Record any requested snapshot manifest.
4. Run `teardown` and satisfy its confirmation deliberately.
5. Run a fresh `list` and prove absence.

If absence cannot be verified, report the pod as potentially billable and
direct immediate attention to the provider console. Never describe the delete
request alone as successful teardown.

## Diagnose failures

- For ambiguous create results, inspect `list`; never blindly retry.
- For missing or ambiguous SSH data, inspect `get POD-ID` and pod readiness.
- For stale tunnels, use `tunnel POD-ID --stop`, confirm the remote service,
  then recreate the mapping.
- For teardown verification failure, assume ongoing billing until a fresh query
  proves absence.
- For missing commands, check the task-specific prerequisites rather than
  installing unrelated tooling.

State clearly whether evidence came from mocks, local containers, provider API
queries, or a real pod/GPU. Do not upgrade one evidence level into another.

## Change the project

Follow `AGENTS.md` and the `.jagent/planning/` ticket/worktree convention. Keep
CLI help, user guides, operational caveats, tests, and planning evidence aligned
when behavior changes.

Run the verification appropriate to the change:

```sh
bash -n bin/water-spider scripts/bump-version.sh tests/run.sh \
  tests/release.sh tests/fakes/* docker/*.sh
shellcheck bin/water-spider scripts/bump-version.sh tests/run.sh \
  tests/release.sh tests/fakes/* docker/*.sh
./tests/run.sh
./tests/release.sh
git diff --check
```

Do not perform a live test merely because deterministic tests pass. Live tests
require separate authorization and the same cost/teardown controls as any other
billable operation.

## Report completion

Include:

- what was inspected or changed;
- the pod IDs, image/template, and command class involved, when applicable;
- which checks passed and their evidence level;
- artifact locations;
- teardown and independent absence status for every live pod touched;
- any remaining potentially billable or unverified state.
