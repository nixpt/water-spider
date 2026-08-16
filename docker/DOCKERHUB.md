<p align="center">
  <img src="https://raw.githubusercontent.com/nixpt/water-spider/main/assets/banner-1280x425.png" alt="Water Spider — GPU lifecycle orchestration">
</p>

# water-spider

A cost-conscious RunPod GPU lifecycle CLI and control-pod image family. Create,
inspect, connect, tunnel, snapshot, and tear down GPU pods without repeatedly
hand-writing the provisioning workflow.

Source, issues, and complete documentation:
[`nixpt/water-spider`](https://github.com/nixpt/water-spider)

## Choose an image

| Tag | Purpose | Typical invocation |
|---|---|---|
| `latest` | Lightweight, one-shot CLI | `docker run --rm nixpt/water-spider gpus --available` |
| `pod` | Persistent CPU control pod that manages other pods | SSH in, then run `water-spider` |
| `v2` | CUDA control pod with llama.cpp and the Hugging Face CLI | Orchestrate and run inference on one GPU pod |

The tags are separate products rather than progressively larger versions of
the same image. Use `latest` from your own machine, `pod` for a small always-on
orchestrator, and `v2` only when the control pod also needs GPU inference.

## Quick start

```sh
docker pull nixpt/water-spider:latest

docker run --rm -it \
  -v "$HOME/.runpod:/root/.runpod:ro" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -p 8080:8080 \
  nixpt/water-spider gpus --available
```

The CLI requires a RunPod API key in the mounted RunPod configuration. See the
[installation and command guide](https://github.com/nixpt/water-spider#install)
before creating a billable pod.

## Cost-safety model

Water-spider treats cost safety as its primary invariant:

- idempotency keys prevent accidental duplicate creation;
- teardown does not report success until the pod is independently absent;
- malformed or ambiguous provider responses fail visibly;
- deterministic tests never access credentials, create pods, or open SSH
  connections.

Live RunPod use still incurs provider charges. Set an explicit budget and
teardown deadline before creating resources.

## Image details

The image definitions, build arguments, RunPod template IDs, validation scope,
and GPU notes live in the maintained
[Docker image guide](https://github.com/nixpt/water-spider/blob/main/docker/README.md).

Supported architectures and exact image sizes can change as base images are
rebuilt; inspect the selected tag's Docker Hub metadata before deployment.

## License

Licensed under the
[MIT License](https://github.com/nixpt/water-spider/blob/main/LICENSE-MIT).
