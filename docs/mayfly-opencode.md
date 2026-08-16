# Short-lived agents with Mayfly and OpenCode

Water-spider can supply a private GPU inference endpoint to a short-lived local
coding agent. [Mayfly](https://github.com/nixpt/mayfly) owns the finite task,
TTL, completion check, and optional disposable worktree. OpenCode is the coding
harness. A v2 water-spider pod runs llama.cpp, reachable only through SSH.

```text
Mayfly -> OpenCode -> http://127.0.0.1:8080/v1 -> SSH tunnel -> llama.cpp on pod loopback
```

Keep Mayfly and OpenCode on the local host. This leaves Git credentials, source
worktrees, and task artifacts local while the pod supplies only inference. They
are integration dependencies, not vendored parts of water-spider.

## Prerequisites

- `water-spider`, `mayfly`, `opencode`, `curl`, and `jq` on local `PATH`;
- `buckets` when using Mayfly's recommended `--worktree` isolation;
- a v2 GPU pod, a tool-capable GGUF model, and an explicit cost ceiling and
  teardown deadline.

Install current Mayfly from its repository and install OpenCode using its
upstream instructions. The checked configuration in
[`../integrations/mayfly-opencode/opencode.json`](../integrations/mayfly-opencode/opencode.json)
uses OpenCode's OpenAI-compatible provider.

## Start the agent endpoint

The `llama-agent` recipe binds llama.cpp to pod loopback, enables Jinja/tool
calling, aliases the model as `speedy`, and creates the authenticated tunnel:

```sh
water-spider recipe serve POD-ID \
  /workspace/scratch/models/TOOL-CAPABLE-MODEL.gguf \
  --engine llama-agent --port 8080

curl http://127.0.0.1:8080/v1/models
```

Tool calling depends on the GGUF chat template. `--jinja` enables template
processing; it cannot make a model or template tool-capable. Before trusting an
agent, inspect `http://127.0.0.1:8080/props` and run the qualification below.

## Hatch a task

Copy and tighten the example task. Use a mechanical `done_when`, a short TTL,
and an allowlist that matches the requested change.

```sh
cp integrations/mayfly-opencode/example-task.json /tmp/task.json
$EDITOR /tmp/task.json

integrations/mayfly-opencode/water-spider-mayfly check
integrations/mayfly-opencode/water-spider-mayfly \
  hatch /tmp/task.json --worktree /path/to/repository
```

The wrapper sets `OPENCODE_CONFIG`, `MAYFLY_OPENCODE_MODEL`, and the endpoint
for the process it launches. Override the local port with, for example:

```sh
WATER_SPIDER_LLM_BASE_URL=http://127.0.0.1:9090/v1 \
  integrations/mayfly-opencode/water-spider-mayfly hatch /tmp/task.json
```

Mayfly v0.1.x treats `paths_allow`, `no_spawn`, and budgets primarily as task
instructions rather than a complete security boundary. Use a disposable
worktree, review the diff, and do not expose secrets to an untrusted model.

## Qualify a model and harness

With the tunnel already running, execute the opt-in live fixture:

```sh
integrations/mayfly-opencode/water-spider-mayfly qualify
```

It creates a temporary Git repository, asks the agent to make one constrained
edit, requires a shell check to pass, and rejects changes outside `answer.txt`.
It does not create or delete a pod. Success qualifies that exact model,
template, llama.cpp build, OpenCode version, and Mayfly version—not every model
served by the image.

## When to build Speedy

Start by measuring this path. Fork OpenCode or introduce a smaller `speedy`
harness only if qualification shows a concrete limitation such as excessive
startup cost, unsupported tool-call encoding, or process-control behavior that
cannot be fixed at the integration edge. Keep the same OpenAI-compatible
endpoint and Mayfly task contract so the harness remains replaceable.

Always stop the tunnel, preserve required artifacts, tear down the pod, and
independently confirm it is absent when the work is complete.
