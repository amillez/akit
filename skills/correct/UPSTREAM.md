# correct upstream

`correct` is our port of poteto's `correct` skill from pstack. It is a separate core skill that holds the whole procedure, so `/correct` runs without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/correct/SKILL.md` |
| Compared against | `00b52d954a99ff67802cad428ff19218659f76fd` (pstack `0.15.11`). The file last changed in `9511e60321f7e533a187d62854a3d53a53752874` (2026-10-03) and is identical on `origin/main` at pstack `0.15.12`. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the mistake-class workflow, the fix ladder, and the rule table are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Frontmatter.** Kept `name` and `disable-model-invocation: true`, since `/correct` is explicit-invoke. The description drops "the operator" and names the "correct", "make this mistake impossible", and second-correction triggers for Codex, which reads only `name`, `description`, and `metadata`.
2. **Operator.** "The operator" and "a human's approval" → Agustín.
3. **Named mistake.** When the invocation names a mistake, that class goes first.
4. **Sources.** Each source gains concrete `git` and `gh` commands. Agent instruction files → the project's `CLAUDE.md` and `AGENTS.md`, project skills under `.claude/skills/` and `.agents/skills/`, and the shared skills from `amillez/akit`.
5. **Lint and CI.** → the project's own lint and the command its CI already runs, so local and CI can't drift.
6. **Proof.** The new lint, type error, or test failing on the commit that made the mistake, plus Argent or the project's `verify-*` skill when the fix changes UI behavior.
7. **Skill rules.** A rule that belongs in a shared skill lands in a worktree of `amillez/akit` per amillez-mode's Authoring a skill playbook, never in an installed copy.
8. **Sibling links.** Optional relative links to amillez-mode's Encode Lessons in Structure and Test Behavior, Not Implementation principles and its Authoring a skill and Opening a PR playbooks. amillez-mode is core and installs beside this skill, so the links resolve in the repo and after install. The skill never requires loading amillez-mode.
9. **Ending.** Ends with Opening a PR. Agents never merge.
10. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
