# Contributing to water-spider

water-spider controls resources that incur real charges. Contributions are
welcome from humans and coding agents, but changes to pod creation and teardown
receive a higher level of scrutiny than ordinary CLI plumbing: failure can mean
duplicate pods, lost artifacts, or an idle GPU continuing to bill.

## Before you start

1. Read `README.md` for the supported workflows and `STATE.md` for what has
   actually been live-tested.
2. Run `dejavue context` to load the repository's durable operating rules.
3. Read `.jagent/planning/RULES.md`, then check `TASKS.md` and the associated
   ticket before changing code.
4. For non-trivial unplanned work, file a `WATERS-NNN` ticket from
   `.jagent/planning/templates/ticket.md` first.

## Safety rules

- Never blindly retry pod creation. An ambiguous result must be inspected before
  another billable request is sent.
- Never report teardown as successful until a fresh pod listing confirms that
  the target is absent.
- Never create a billable test pod without an explicit cost cap and teardown
  deadline.
- Never expose API keys, registry credentials, SSH keys, or unredacted RunPod
  configuration in fixtures, logs, issues, or pull requests.
- Keep the default path on `runpodctl`; direct GraphQL is reserved for fields its
  CLI does not expose.
- Keep external-command behavior behind the command boundary so the deterministic
  fake-based suite can exercise it without network access.

## Development workflow

Use one branch and worktree per ticket, as required by
`.jagent/planning/RULES.md`. Keep one logical change per pull request and update
the ticket, task index, README, and state documentation in the same change when
their claims are affected.

Before submitting:

```sh
bash -n bin/water-spider scripts/bump-version.sh tests/run.sh tests/release.sh tests/fakes/* docker/*.sh
shellcheck bin/water-spider scripts/bump-version.sh tests/run.sh tests/fakes/* docker/*.sh
./tests/run.sh
./tests/release.sh
git diff --check
```

The command suite must remain credential-free and non-billable. If behavior also
requires live validation, include sanitized evidence, the maximum authorized
cost, and confirmation that the pod was independently verified absent afterward.

## Commits and releases

Use conventional-commit subjects where practical:

- `feat:` for user-visible capability
- `fix:` for corrected behavior
- `docs:`, `test:`, or `chore:` for supporting changes
- `feat!:` or a `BREAKING CHANGE` footer for incompatible changes

Versioning is handled by `scripts/bump-version.sh` and the release workflow.
Task worktrees should use Jokersquad's `git-ops seal`; only the primary checkout
ships reviewed work. Do not create release tags casually: a tag is part of the
public compatibility history. See `docs/repository-operations.md`.

## For coding agents

- Treat generated instruction adapters as generated files. Edit
  `.dejavue/context.md`, then run `dejavue export --target <tool> --replace`.
- Reproduce a ticket against its current base before fixing it.
- Do not turn mocked results into claims of live RunPod verification.
- Record durable architectural decisions with Dejavue; routine edits and test
  results belong in commits and tickets instead.

## What not to contribute

- A second implementation of an operation already supported reliably by
  `runpodctl`.
- Automatic retry loops around billable or destructive API calls.
- Full-disk backup behavior disguised as the lightweight `snapshot` manifest.
- Dependencies added only to simplify a few lines of portable shell.
- Fleet-specific requirements in otherwise standalone commands; fleet integration
  must remain optional and clearly labeled.
