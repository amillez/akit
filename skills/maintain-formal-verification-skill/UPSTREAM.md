# maintain-formal-verification-skill upstream

`maintain-formal-verification-skill` is our port of poteto's `maintain-formal-verification-skill` skill from pstack. It pairs with [`create-formal-verification-skill`](../create-formal-verification-skill/UPSTREAM.md), which it points at when no verify skill exists.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/maintain-formal-verification-skill/` (`SKILL.md`) |
| Compared against | `c742dd61706fbacc1b95f1a20b7b988cf096ce6c` (pstack `0.15.36`). `SKILL.md` last changed in `7b353f78f6ec193bdbe48ed8059444eb09b6878e` (2026-10-19), which added it. Ours is byte-for-byte that text. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the upkeep loop, the four outcomes, and the drift-or-bug judgment are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Output location.** Upstream names no skill directory, so no change was needed. The skill finds a verify skill by what it does, which covers `.claude/skills/` and `.agents/skills/`.
2. **Dependency age.** Not applicable. The skill picks no tool. It reruns the one the verify skill names.
3. **Skill text only.** `SKILL.md` is byte-for-byte upstream, frontmatter included, and names no host and carries no attribution or long dashes. It keeps `disable-model-invocation: true`, so `/maintain-formal-verification-skill` loads it. Attribution lives here.
