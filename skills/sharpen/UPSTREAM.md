# sharpen upstream

`sharpen` is our port of poteto's `sharpen` skill from pstack. It is a separate core skill that holds the whole pre-task check, so it applies without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/sharpen/` (`SKILL.md`) |
| Compared against | `e5136d82418d2db3165ea1050d17577cd618cc05` (pstack `0.15.25`). The directory last changed in `79afd75d5bd51383fbb526b72f36db03180b8301` (2026-10-13). Ours is byte-for-byte that text. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the pre-task check (expert approach, real goal, specification level, one outside check) is poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to it.

## Local changes

1. **Verbatim.** `SKILL.md` is byte-for-byte upstream, frontmatter included. It keeps `disable-model-invocation: true`, so the model never invokes it on its own and `/sharpen` loads it.
2. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
