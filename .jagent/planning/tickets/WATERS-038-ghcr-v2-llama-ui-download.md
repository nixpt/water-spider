# WATERS-038 — release: the GHCR v2 image fails on llama.cpp's UI download

| Field | Value |
|-------|-------|
| **ID** | WATERS-038 |
| **Priority** | P1 |
| **Status** | Open |
| **Phase** | Release |
| **Assignee** | — |
| **Dependencies** | — |
| **Estimated effort** | S |

## Problem

The `release` workflow's **publish GHCR (v2)** job has failed on every main merge since 2026-11-19 (7f54afb, c6aaa7c,
ddd688b, 539aef4, 00f7ccf, 674869d, 6926a86). The last success was fef27ea on 2026-08-30. `bump`, `publish GHCR
(latest)` and `publish GHCR (pod)` still pass, so version tags are cut (v0.8.1..v0.8.3), but no v2 image has been
published for any of them.

The failing step is `Dockerfile.v2`'s llama.cpp build (`LLAMACPP_REF=b10451`, unchanged since 9273f15, 2026-08-16).
llama.cpp's CMake fetches its web UI assets at build time, and both sources now return an HTTP error (run
44715745933):

    -- UI: downloading from b1: https://huggingface.co/buckets/ggml-org/llama-ui/resolve/b1/dist.tar.gz
    -- UI: download dist.tar.gz from b1 failed: "HTTP response code said error"
    -- UI: downloading from latest: https://huggingface.co/buckets/ggml-org/llama-ui/resolve/latest/dist.tar.gz
    CMake Error at /opt/llama.cpp/scripts/ui-assets.cmake:291 (message)
    gmake[3]: *** [tools/ui/CMakeFiles/llama-ui-assets.dir/build.make:71: tools/ui/CMakeFiles/llama-ui-assets] Error 1

So the cause is outside the repo: the image build depends on a network fetch that no longer resolves. Why the same
pin built in August is not yet known (the bucket moved or was removed, or the fetch was best-effort then). The
August run logs have expired.

## Success criteria

- [ ] Read `scripts/ui-assets.cmake` at `b10451` and say in the PR how the fetch is controlled (an option to skip it,
      a local source, or a fallback), quoting the lines.
- [ ] The v2 build no longer depends on that download. In order of preference:
  1. turn the UI fetch off with llama.cpp's own CMake option, if `llama-server` still builds and runs without the web
     UI (the pod uses the API, not the browser UI; confirm by checking the docs and recipes, and state it);
  2. or bump `LLAMACPP_REF` to a tag whose UI source resolves. Record the old and new commit, and re-run the existing
     `llama-server`/`llama-cli` smoke checks in the image;
  3. or vendor a pinned `dist.tar.gz` with a sha256 check. Only if 1 and 2 both fail.
- [ ] The build stays offline-reproducible where it can: no new unpinned downloads.
- [ ] `publish GHCR (v2)` passes on the PR's merge, and the image's recorded `llama.cpp.commit` and build info are
      right. Confirm with `gh run view` and list the run in the READY.
- [ ] `docker/README.md` / `docker/DOCKERHUB.md` note any change (for example "no web UI in v2").

## Notes

Found by arisu on 2026-11-20 while checking main's CI after #18. A heavy docker build: run it in CI, or locally only
with vega's OK (one heavy build at a time box-wide). No GPU needed to build. Nothing goes to HF.
