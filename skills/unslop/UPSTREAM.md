# unslop upstream

`unslop` is our port of poteto's `unslop` skill from pstack. It is a separate core skill that holds the whole slop-pattern catalog, so it applies without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/unslop/` (`SKILL.md`) |
| Compared against | `0b46ec399d55f2829e88822998f53b84944837d3` (pstack `0.15.46`). The directory last changed in `2f87c854fe3e2fcda44ca86b46ede35aad3c46b7` (2026-11-16, #1249), which cut each pattern to one line and dropped the group headings. The rule ids are unchanged (3, 5, 7 to 20, 22 to 33). Ours is byte-for-byte that text. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the slop-pattern catalog and the rewrite process are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Verbatim.** `SKILL.md` is byte-for-byte upstream, frontmatter included. It keeps `disable-model-invocation: true`, so callers link and open the file instead of calling the Skill tool. The rule numbers stay the stable ids other skills cite.
2. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
