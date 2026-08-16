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
current_version="$(cat "$ROOT/VERSION")"
IFS=. read -r version_major version_minor version_patch <<< "$current_version"
next_version="$version_major.$version_minor.$((version_patch + 1))"
git -C "$TEST_REPO" add .
git -C "$TEST_REPO" commit -qm 'chore: bootstrap release'
git -C "$TEST_REPO" tag -a "v$current_version" -m "v$current_version"

tagged_output="$(cd "$TEST_REPO" && BUMPVER_DRY_RUN=1 ./scripts/bump-version.sh 2>&1)"
printf '%s' "$tagged_output" | grep -Fq "HEAD is already tagged v$current_version"

printf 'post-release\n' > "$TEST_REPO/change.txt"
git -C "$TEST_REPO" add change.txt
git -C "$TEST_REPO" commit -qm 'fix: post-release correction'

next_output="$(cd "$TEST_REPO" && BUMPVER_DRY_RUN=1 ./scripts/bump-version.sh 2>&1)"
printf '%s' "$next_output" | grep -Fq "current=$current_version  bump=patch  next=$next_version"
printf '%s' "$next_output" | grep -Fq "would commit + tag v$next_version"

echo 'release bootstrap tests passed'
