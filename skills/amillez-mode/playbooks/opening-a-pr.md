### Opening a PR

Invoked at the end of every other playbook that changes code.

**Worktree.** Work from your own git worktree on a branch named `agent/<bot>/<slug>`, cut from an up-to-date `main`. Never work in the `main` checkout, and never put two agents in one worktree. Subagents that write code get their own worktree or run one at a time in yours. Dirty branch with unrelated work: patch out, fresh worktree, apply. Snarled worktree: reset from `main`, redo minimally.

**Commits.** Commit liberally. Rebase into small, ordered commits before opening PRs. Each commit is a future PR: landable, ordered to tell the story. Amend when the fix belongs in a just-made commit. New commit when separable.

**Before the PR.** Reread your own diff. Delete slop, dead code, debug output, and comments that fail **Comments** in `SKILL.md`. Run the repo's lint, typecheck, and tests on the committed head. Write every PR title, PR description, and commit body with [technical writing](../references/technical-writing.md), then apply [unslop](../references/unslop.md). Apply every technical-writing layer except Diátaxis. Use one word for each action, keep articles, and avoid `-ing` when a plain verb works.

**Titles.** Use Conventional Commits in the form `type(scope): subject`. Use `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, or `perf` as the type. Use the changed area as the scope. Keep the subject short and imperative. Name a real symbol when one carries the change. For example, `fix(checkout): retry payment intent on 409`. Do not add a trailing period. Follow the repo's own title convention when it has one.

**Descriptions.** The PR body is a briefing, not the lab notebook. A reviewer who has the diff should learn why the change exists, what is out of scope, and how you proved the change works. The squash commit body is the PR body. If the body would make the squash commit longer than about 40 lines, cut the body.

Use these sections in order. Drop a section when it has nothing to say.

- `## Why`. State the intent and approach in one or two short paragraphs. Do not list SHAs or rebase genealogy.
- `## Scope`. Use bullets to list real symbols and paths. Name both sides of a rename or retarget. State what is in and out only when the boundary matters. Do not write a file-by-file essay.
- `## Tradeoffs`. Name only rejected alternatives that a reviewer would otherwise ask about. Skip this section when there was no real choice.
- `## Blast Radius`. In one to three sentences, name who or what the change touches and why the change is safe or risky. For a diff you don't fully trust, run [Blast radius](blast-radius.md) first and state its one safety fact here, proven or marked unproven.
- `## Verification`. Name each real run path and its outcome. For a performance change, report one primary number with its unit in `before → after` form. Embed or link proof media here.

**Proof media.** Screenshots and videos never go on the PR branch. Push them to the repo's `media` branch under `proof/<pr-number-or-slug>/`, creating it as an orphan branch the first time. Link them with GitHub blob URLs (`https://github.com/<owner>/<repo>/blob/media/proof/<slug>/<file>`, with `?raw=true` for inline images), never `raw.githubusercontent.com`. Put the GPT 6 Luna Max pass/fail next to each asset. Do not paste full SHAs, lane recitals, file-by-file checklists, or "CLEAN" verdicts. Do not use `## Summary` or `## Test plan` boilerplate. A commit body does not restate its subject.

**Size and stacks.** Prefer five narrow PRs to one large PR. Use `gh` for every PR operation. A stack is a base-branch chain. The root PR targets `main`. Each child branch rebases onto its parent's exact tip and its PR targets the parent branch (`gh pr create --base <parent-branch>`, retarget with `gh pr edit <pr> --base <parent-branch>`). Branch from `main` only for independent work. Rebase on `main` before substantial stack work. Force-push only your own branch, with `--force-with-lease`.

**Readiness.** Open every PR ready, never as a draft. With `gh`, omit `--draft`. If a PR still opens as a draft, run `gh pr ready <number>`. Run `gh pr view <number>` before you refer to PR status.

**Never merge.** Do not run `gh pr merge`, arm auto-merge, or close the PR. Only Agustín's explicit say-so merges.

**After opening.** Tear down what the task started (simulators, emulators, Metro and dev servers, matching Expo CLI processes, watchers), then check that no used Metro port is listening. Post the PR URL and stop. Opening a PR does not start a babysit. When you are sent back with review comments, apply Agustín's comments without asking, verify each automated review claim against the code, push one batched fix wave, and report. Push back when feedback drifts from the intent.

A subagent that opens a PR posts the URL and returns to its parent.
