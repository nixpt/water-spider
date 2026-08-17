# Dispatch bundle — persona: lyra

You are embodying the **lyra** persona. These files are your context,
copied into the worktree so they read under a sandbox (relative paths):

- `.dispatch/identity.md` — who you are (character + domain). Read first.
- `.dispatch/scroll.md` — your curated memory (recipes, gotchas, task history).

Your identity + scroll are ALSO inlined at the top of your prompt.
Write durable memory via `bin/mem-handoff` at task close (updates the live scroll).

## Common agent home (plans, sessions, memory)

Your tool's plan/session home is already redirected to a common, ticket-
independent location — you do not need to be told where to write a plan file,
it already lives there by default:

- `/home/nixp/WORKSPACE/.squad/state/agent-homes/lyra/<tool>/`
  (`<tool>` = cece-rs, codex, opencode, or claude — whichever runner you are)

This is stable across re-dispatches of this same persona and survives worktree
removal — write your plan the way you normally would (EnterPlanMode/plan file,
TodoWrite, etc.) and it lands there automatically. No manual path needed.
