# sharpen upstream

`sharpen` is our port of poteto's `sharpen` skill from pstack. It is a separate core skill that holds the whole prompt rewrite, so it applies without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/sharpen/` (`SKILL.md`) |
| Compared against | `bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7` (pstack `0.15.42`). The directory last changed in `bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7` (2026-11-15), which rewrote the prompt's last line. The rewritten prompt now asks the agent to prototype any choice an experiment can settle and to recommend an option from what it observed. Only product or preference choices that no experiment can settle stay with the user. Before that, `88d47514b82e7c44f00f2b2a72ff6dd12158038c` (2026-10-20) restored the original prompt, so `/sharpen` answers four questions and hands back the rewritten prompt instead of doing the task. Ours is byte-for-byte the current text. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the prompt rewrite (what a top professional would add, the rawest material, their methods and tools, one outside check) is poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to it.

## Local changes

1. **Verbatim.** `SKILL.md` is byte-for-byte upstream, frontmatter included. It keeps `disable-model-invocation: true`, so the model never invokes it on its own and `/sharpen` loads it.
2. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
