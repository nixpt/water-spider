# RunPod API drift, 2026-11 (WATERS-024)

Audited 2026-11-19 on [zorro] with runpodctl 2.1.9, read-only calls only.

**Cause.** runpodctl 2.x sends `pod create|list|get|delete` to REST v1 at
`https://rest.runpod.io/v1`. That host no longer resolves (`getent`/`dig`: NXDOMAIN).
RunPod's docs now give the REST base URL as `https://api.runpod.io/v2`; `api.runpod.io/v1/pods`
returns 404 and `api.runpod.io/v2/pods` returns 200 with a different (paginated) shape. runpodctl
v3.0.0 moved its REST commands to v2 and v3.1.1 (2026-11-12, "route all REST commands through
RUNPOD_API_URL & use rest V2 for everything") makes `https://api.runpod.io/v2` the default.
GraphQL (`api.runpod.io/graphql`) is unchanged and works.

## Audit (runpodctl 2.1.9)

| Command | Before | Path | Now |
|---|---|---|---|
| `create` (default, no GraphQL-only flag) | BROKEN | `runpodctl pod create` (REST v1) | Refuses with a clear message if runpodctl < 3.1.1 (nothing is created). Works on >= 3.1.1 per source/release notes; not live-verified (needs a billed pod). |
| `create` (GraphQL flags / registry-auth-id) | create ok, guards BROKEN | `podFindAndDeployOnDemand` + `pod list` guard | Guards now via GraphQL; fails closed. |
| create duplicate guard / pre-create / post-create listing | BROKEN (pre-create swallowed the error: `|| echo "(none)"`) | `runpodctl pod list` | `ws_pods_json` (GraphQL). Pre-create and ledger-replay listing failures now REFUSE to create. |
| `list` | BROKEN | `pod list` | GraphQL |
| `status` | BROKEN pods half; `user` half worked | `pod list` + `runpodctl user` (GraphQL) | GraphQL |
| `get` | BROKEN | `pod get` | GraphQL `pod(input:{podId})` |
| `teardown` delete | BROKEN | `pod delete` (REST) | GraphQL `podTerminate` mutation (fakes only; NOT run live) |
| `teardown` verify | BROKEN | `pod list` | fresh GraphQL listing; failure => UNKNOWN |
| `connect` `tunnel` `snapshot` `recipe serve` `gui` | works (not-found path checked live) | `runpodctl ssh info` (GraphQL in 2.1.9: returns a clean "not found", not a DNS error) + ssh | unchanged; real-pod output shape still unverified (as before) |
| `send` `receive` | works | croc via runpodctl, no API | unchanged |
| `gpus` | works | `runpodctl gpu list` (GraphQL) | unchanged |
| `scaffold`, `recipe list` | n/a | local | unchanged |
| mcp/ server | inherits | shells out to `water-spider` | no code change; inherits the fix |

## Decision: GraphQL helper, plus a version gate on create

* Read paths and terminate use GraphQL (`ws_gql`, `ws_pods_json`, `ws_pod_json`, `ws_pod_terminate`).
  This does not depend on which runpodctl is installed, reuses the existing `ws_api_key`, and
  is the cost-safety surface (duplicate guard, teardown verify), so it should not move when the
  CLI's REST base URL moves again.
* `runpodctl pod create` is still used by the default create path; it is gated on
  runpodctl >= 3.1.1 (`ws_require_rest_capable_runpodctl`).
* Invariants kept: no blind retry of create; "gone" only after a fresh successful listing that
  lacks the id; a failed verify query is UNKNOWN; the guard fails closed.

## Upgrading runpodctl

3.1.1 is the first release verified here to target `api.runpod.io/v2` by source. Do not set
`RUNPOD_API_URL` to a v1 URL. Unverified: a live `pod list`/`pod create` run of 3.1.1 (the sandbox
declined executing the downloaded binary with the API key).
