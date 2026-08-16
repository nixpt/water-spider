#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_REPO="$(mktemp -d)"
trap 'rm -rf "$TEST_REPO"' EXIT

git -C "$TEST_REPO" init -q -b main
git -C "$TEST_REPO" config user.name test
git -C "$TEST_REPO" config user.email test@example.invalid
mkdir -p "$TEST_REPO/scripts"
cp "$ROOT/scripts/bump-version.sh" "$TEST_REPO/scripts/bump-version.sh"
cp "$ROOT/CHANGELOG.md" "$TEST_REPO/CHANGELOG.md"
cp "$ROOT/VERSION" "$TEST_REPO/VERSION"
git -C "$TEST_REPO" add .
git -C "$TEST_REPO" commit -qm 'chore: bootstrap release'
git -C "$TEST_REPO" tag -a v0.1.0 -m v0.1.0

tagged_output="$(cd "$TEST_REPO" && BUMPVER_DRY_RUN=1 ./scripts/bump-version.sh 2>&1)"
printf '%s' "$tagged_output" | grep -Fq 'HEAD is already tagged v0.1.0'

printf 'post-release\n' > "$TEST_REPO/change.txt"
git -C "$TEST_REPO" add change.txt
git -C "$TEST_REPO" commit -qm 'fix: post-release correction'

next_output="$(cd "$TEST_REPO" && BUMPVER_DRY_RUN=1 ./scripts/bump-version.sh 2>&1)"
printf '%s' "$next_output" | grep -Fq 'current=0.1.0  bump=patch  next=0.1.1'
printf '%s' "$next_output" | grep -Fq 'would commit + tag v0.1.1'

echo 'release bootstrap tests passed'
