### Opening a PR

Invoked at the end of every other playbook that changes code.

**Worktree.** Work from your own Orca worktree on a branch named `agent/<bot>/<slug>`, created per [Orca launches](../references/orca-launch.md#start-a-session-in-a-worktree). Never work in the `main` checkout, and never put two agents in one worktree. Subagents that write code get their own worktree or run one at a time in yours. Dirty branch with unrelated work: patch out, fresh worktree, apply. Snarled worktree: reset from `main`, redo minimally.

**Commits.** Commit liberally. Rebase into small, ordered commits before opening PRs. Each commit is a future PR: landable, ordered to tell the story. Amend when the fix belongs in a just-made commit. New commit when separable.

**Before the PR.** Reread your own diff. Delete slop, dead code, debug output, and comments that fail **Comments** in `SKILL.md`. Run the repo's lint, typecheck, and tests on the committed head. Write every PR title, PR description, and commit body with [technical writing](../references/technical-writing.md), then apply the sibling [`unslop`](../../unslop/SKILL.md) skill. Apply every technical-writing layer except Diátaxis. Use one word for each action, keep articles, and avoid `-ing` when a plain verb works.

**Titles.** Use Conventional Commits in the form `type(scope): subject`. Use `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, or `perf` as the type. Use the changed area as the scope. Keep the subject short and imperative. Name a real symbol when one carries the change. For example, `fix(checkout): retry payment intent on 409`. Do not add a trailing period. Follow the repo's own title convention when it has one.

**Descriptions.** The PR description is the review guide. A reviewer who has the diff should learn why the change exists, what it could break, how you proved it works, and where to start reading, without asking you anything. Write short, simple sentences with few identifiers. Do not write walls of text. Keep each section to what a reviewer needs.

Put each section under a `##` heading, not a bold lead-in, so the sections stand apart. Use these sections in order. Drop a section when it has nothing to say.

- `## Summary and risk`. State what the PR does in two or three sentences, then a risk level (low, medium, or high) with the reason. Do not list SHAs or rebase genealogy.
- `## What changed and why`. One line per decision with its reason. Name real symbols and paths, and both sides of a rename or retarget. Name a rejected alternative only when a reviewer would otherwise ask about it. Do not write a file-by-file essay.
- `## Blast radius`. In one to three sentences, name who or what the change touches and why the change is safe or risky. For a change behind a kill switch, say what the flag gates and what ships outside it. For a diff you don't fully trust, run the [`blast-radius`](../../blast-radius/SKILL.md) skill first and state its one safety fact here, proven or marked unproven.
- `## Proof`. Name each real run path and its outcome, with the pass or fail against the success criteria next to each asset. Screenshots and video render inline here. For a performance change, report one primary number with its unit in `before → after` form.
- `## How to reproduce`. The `verify-<app>` commands, or the exact commands you ran, in code blocks.
- `## Review order`. Critical files first, each linked to exact lines on the PR head.
- `## Critical parts and why`. The few hunks a reviewer must not skim, and what breaks if they are wrong.
- `## Diagrams`. Mermaid, only when the change spans modules or changes a flow.

**Proof media.** Screenshots, videos, and logs never go into git, on any branch. Save local proof under `~/agent-work/proof/<slug>/`, the one directory outside the working directories that the akit install lets Claude Code read without a prompt. Attach each screenshot and video inline in `## Proof` with `gh pr create|edit --attach`, so it renders in the description, never only behind a link. Do not paste full SHAs, lane recitals, file-by-file checklists, or "CLEAN" verdicts. Do not use `## Test plan` boilerplate. A commit body does not restate its subject.

**Review guide.** For a non-trivial PR, and for any PR with visual proof, write the body with the sibling [`review-guide`](../../review-guide/SKILL.md) skill. It covers the Mermaid light theme, the `--attach` upload, the check that the body holds user-attachments URLs and no local paths, and the in-place update after each push. Skip it for docs-only PRs, which still use the sections above.

**Size and stacks.** Prefer five narrow PRs to one large PR. Use `gh` for every PR operation. A stack is a base-branch chain. The root PR targets `main`. Each child branch starts on its parent's exact tip and its PR targets the parent branch (`gh pr create --base <parent-branch>`, retarget with `gh pr edit <pr> --base <parent-branch>`). Branch from `main` only for independent work. Rebase on `main` before substantial stack work. While a stack is under review, land fixes as new commits and restack a child by merging its parent into it. Save any rebase for one pass after approval. Force-push only your own branch, with `--force-with-lease`. A PR that replaces other PRs lists each unresolved thread from them in its body as an open question, with a link.

**Readiness.** Open every PR ready, never as a draft. With `gh`, omit `--draft`. If a PR still opens as a draft, run `gh pr ready <number>`. Run `gh pr view <number>` before you refer to PR status. Do not report a PR ready for review, yours or a worker's, until `gh pr checks <number> --watch` exits 0.

**Never merge.** Do not run `gh pr merge`, arm auto-merge, or close the PR. Only Agustín's explicit say-so merges.

**After opening.** Tear down what the task started (simulators, emulators, Metro and dev servers, matching Expo CLI processes, watchers), then check that no used Metro port is listening. Post the PR URL and stop. A run that is interrupted after its PR opens, such as a dependency (deps) routine, reports `PR opened` with the URL, not a failure. A failure report invites a blind retry that opens a second PR. Opening a PR does not start a babysit. When you are sent back with review comments, apply Agustín's comments without asking, verify each automated review claim against the code, push one batched fix wave, and report. Push back when feedback drifts from the intent.

A subagent that opens a PR posts the URL and returns to its parent.
