# Repository operations

water-spider uses the shared repository-management tools in
`/workspace/projects/jokersquad/bin`; it does not vendor private fleet scripts
into the public repository.

## Tooling map

- `bump-version` installs the self-contained release script and workflow.
- `gh-ruleset` applies GitHub rulesets. water-spider uses `fleet-default`,
  preventing deletion and force-push of the default branch.
- `git-ops` implements the two-stage worktree flow. Use `git-ops seal` in task
  worktrees; only the primary/foreman checkout ships to GitHub.
- `gh-repo-audit` reports visibility, default branch, pull requests, staleness,
  and ruleset presence.
- `gh-branch-sweep` removes old merged branches while protecting checked-out
  worktrees and the default branch.

The referenced `cece-code/crates/text-editor-core` tree contains editor buffer,
capability, language, state, VFS, and workspace modules, but no GitHub ruleset,
git-ops, release, or repository-management implementation. It is unrelated to
this integration.

## Protection policy

```sh
/workspace/projects/jokersquad/bin/gh-ruleset \
  --repo nixpt/water-spider --policy fleet-default --dry-run
/workspace/projects/jokersquad/bin/gh-ruleset \
  --repo nixpt/water-spider --policy fleet-default
```

Do not apply `fleet-pr-required` to `main` while release automation pushes its
version commit directly. Jokersquad documents and has live-reproduced that
conflict: the empty bypass list causes GitHub to reject the bot's release push.

## Release bootstrap

The first release needs one commit containing `VERSION=0.1.0`, an annotated
`v0.1.0` tag on that commit, and one push of branch plus tag. The exact-tag
guard makes that workflow run a successful no-op. Each later push with untagged
work creates the next version.
