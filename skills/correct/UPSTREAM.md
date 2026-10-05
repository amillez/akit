# correct upstream

`correct` is our port of poteto's `correct` skill from pstack. It is the `/correct` entry point. The procedure lives in amillez-mode's [Correct](../amillez-mode/playbooks/correct.md) playbook.

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

1. **Split.** The procedure is amillez-mode's [`playbooks/correct.md`](../amillez-mode/playbooks/correct.md), so the router and the repeated-correction trigger reach it like every other playbook. Its remaps are listed in the `correct/SKILL.md` row of amillez-mode's per-file verdicts. This skill only loads amillez-mode and runs the playbook.
2. **Frontmatter.** Kept `name` and `disable-model-invocation: true`, since `/correct` is explicit-invoke. A repeated correction reaches the playbook through amillez-mode instead. The description drops "the operator" and names the "correct", "make this mistake impossible", and second-correction triggers for Codex, which reads only `name`, `description`, and `metadata`.
3. **Named mistake.** When the invocation names a mistake, that class goes first.
4. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
