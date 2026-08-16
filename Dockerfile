# water-spider — RunPod pod-orchestration CLI, containerized.
#
# Deliberately NOT the nixpt/zorro image: this ships the CLI tool itself
# (runs on the machine driving pod lifecycle — your laptop/workstation),
# not an inference runtime. No CUDA, no model weights, no ML toolchain.
# Base + runpodctl + a handful of small CLI deps; that's the whole image.
#
# Build:
#   docker build -t nixpt/water-spider:2.9.0 .
#
# Run (mount your RunPod API key + SSH key so `create`/`connect`/`tunnel`
# actually work; -it so the ssh-based subcommands get a real terminal):
#   docker run --rm -it \
#     -v "$HOME/.runpod:/root/.runpod:ro" \
#     -v "$HOME/.ssh:/root/.ssh:ro" \
#     -p 8080:8080 \
#     nixpt/water-spider gpus --available
#
# `gui`'s xpra path is NOT baked in (keeps the image small — xpra pulls a
# real X client stack, and the script already falls back to raw `ssh -X`/
# `-Y` when xpra isn't present). Raw X11 forwarding from inside the
# container needs the host X socket + DISPLAY passed through:
#   -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix
# Build with --build-arg INCLUDE_XPRA=1 to bake xpra in instead.

FROM rust:1.96-alpine AS water-spider-mcp-builder

RUN apk add --no-cache musl-dev
WORKDIR /build/mcp
COPY mcp/Cargo.toml mcp/Cargo.lock ./
COPY mcp/src ./src
RUN cargo build --locked --release

FROM debian:bookworm-slim

# Pinned to a specific runpodctl release + verified sha256 (checksums file
# published alongside the release, not derived by hand) — a curl-to-root
# install with no verification is exactly the supply-chain shape this
# fleet avoids (see: NO AUR — supply-chain-attack posture).
ARG RUNPODCTL_VERSION=2.9.0
ARG RUNPODCTL_SHA256=06e6f54957db79d5cd9f1909a7f1d365076826751ba2f5df65d75dde43a64148
ARG INCLUDE_XPRA=0

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        openssh-client \
        procps \
        iproute2 \
        bsdextrautils \
        xauth \
        $( [ "$INCLUDE_XPRA" = "1" ] && echo xpra ) \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/runpodctl \
        "https://github.com/runpod/runpodctl/releases/download/v${RUNPODCTL_VERSION}/runpodctl-linux-amd64" \
    && echo "${RUNPODCTL_SHA256}  /usr/local/bin/runpodctl" | sha256sum -c - \
    && chmod +x /usr/local/bin/runpodctl

COPY bin/water-spider /usr/local/bin/water-spider
COPY --from=water-spider-mcp-builder /build/mcp/target/release/water-spider-mcp /usr/local/bin/water-spider-mcp
RUN chmod +x /usr/local/bin/water-spider

# scaffold subcommand needs a sibling jokersquad checkout — not present in
# this image by design (fleet-internal only, see bin/water-spider's own
# header). Every other subcommand works standalone.

ENTRYPOINT ["/usr/local/bin/water-spider"]
CMD ["--help"]
