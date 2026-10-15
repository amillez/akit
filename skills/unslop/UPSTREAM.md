# unslop upstream

`unslop` is our port of poteto's `unslop` skill from pstack. It is a separate core skill that holds the whole slop-pattern catalog, so it applies without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/unslop/` (`SKILL.md`) |
| Compared against | `e5136d82418d2db3165ea1050d17577cd618cc05` (pstack `0.15.25`). The directory last changed in `bc697d0a5a163cec979e362b601e36f5616083fd` (2026-10-11). Ours is byte-for-byte that text. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the slop-pattern catalog and the rewrite process are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Verbatim.** `SKILL.md` is byte-for-byte upstream, frontmatter included. It keeps `disable-model-invocation: true`, so callers link and open the file instead of calling the Skill tool. The rule numbers stay the stable ids other skills cite.
2. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
