---
name: correct
description: >-
  Find the mistakes agents keep repeating in a repo and make each one
  impossible. Architecture first, then types, then a lint or CI check whose
  error names the fix, then behavior tests, and agent rules last. Each new
  check is proven to fail on a real past mistake. Use for "correct",
  "/correct", "make this mistake impossible", or the second time the same
  mistake is corrected.
disable-model-invocation: true
---

# Correct

Agustín keeps correcting agents in this repo for the same mistakes. Change the repo so the next agent can't make them. This is the runnable form of [Encode Lessons in Structure](../amillez-mode/principles/encode-lessons-in-structure.md).

Assume every contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that compiles. Design the repo so a change that looks right from one file is right for the whole repo.

## Find the mistake classes

First, read recent commits, reverts, review comments, agent instruction files, and comments that explain workarounds. Group the mistakes into classes. A class counts once it has happened twice. When the invocation names a mistake, that class goes first.

- Commits and reverts. `git log`, `git log --grep=Revert`, `git log -S`, `git blame`.
- Review comments. `gh pr list --state all`, `gh pr view <n> --comments`, `gh api repos/<owner>/<repo>/pulls/<n>/comments`.
- Agent instruction files. The project's `CLAUDE.md` and `AGENTS.md`, project skills under `.claude/skills/` and `.agents/skills/`, and the shared skills from `amillez/akit`.
- Workaround comments. Comments that warn the next reader off an obvious path.

## Fix each class at the highest level that works

1. **Eliminate it with architecture.** Give each piece of state one owner and each task one supported way. Hide internals so the wrong import fails. Replace hand-synced lists with one source of truth. Delete old ways and dead code an agent would copy.
2. **Enforce it with types so the bad state can't be written.** If bad code still compiles, add a rule to the project's lint or a check to its CI whose error names the file, type, or function to use instead. If the pattern is already common, fail only when a change adds more.
3. **Test the behavior.** Fix or delete any test that would still pass if every function it calls returned nothing, per [Test Behavior, Not Implementation](../amillez-mode/principles/test-behavior-not-implementation.md).
4. **Write docs or agent rules last, only for judgment calls.** Nothing fails when an agent skips them. A rule that belongs in a shared skill lands in a worktree of `amillez/akit` per [Authoring a skill](../amillez-mode/playbooks/authoring-a-skill.md), never in an installed copy.

## Fix and prove

Then fix the most frequent classes now, one commit each. Prove each new check fails on a real past mistake. Run it against the commit that made the mistake, in a scratch worktree at that SHA or with the bad diff re-applied, and paste the failing output. The new lint, type error, or test is the proof. When the fix changes UI behavior, also prove it on the real surface with Argent or the project's `verify-*` skill.

Run the same command locally and in CI. Wire the check into the command CI already runs (the package script, Makefile target, or workflow step) so the two can't drift. Exceptions go on the offending line with a reason, an expiry date, and Agustín's approval.

End with [Opening a PR](../amillez-mode/playbooks/opening-a-pr.md). Never merge.

## Keep the rule table

Last, keep a table in the project's agent instruction file (`AGENTS.md` or `CLAUDE.md`, whichever the repo's agents read) that pairs each rule with what enforces it. When Agustín corrects you, fix the mistake and add the rule. If the rule was already there and nothing enforces it, that's a repeat, so fix it at the highest level in the same change. Drop a rule once its mistake can't happen.

**Reply:** each class with its evidence, the level you picked, and why a higher level didn't work.
