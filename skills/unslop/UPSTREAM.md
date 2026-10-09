# unslop upstream

`unslop` is our port of poteto's `unslop` skill from pstack. It is a separate core skill that holds the whole slop-pattern catalog, so it applies without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/unslop/` (`SKILL.md`) |
| Compared against | `00b52d954a99ff67802cad428ff19218659f76fd` (pstack `0.15.11`). The directory last changed in `70b2dc8b4b85c8d5648624ca40d692c421fff32f` (2026-09-23) and is identical on `origin/main` at pstack `0.15.15` (`df581122cde17e6e27686b5a448bde23e4ad4318`). |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the slop-pattern catalog and the rewrite process are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Verbatim.** `SKILL.md` is byte-for-byte upstream, frontmatter included. It keeps `disable-model-invocation: true`, so callers link and open the file instead of calling the Skill tool. The rule numbers stay the stable ids other skills cite.
2. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
