# sharpen upstream

`sharpen` is our port of poteto's `sharpen` skill from pstack. It is a separate core skill that holds the whole prompt rewrite, so it applies without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/sharpen/` (`SKILL.md`) |
| Compared against | `e73df471cd4bd918367e99f3dd9c51bd53ddf5f0` (pstack `0.15.32`). The directory last changed in `88d47514b82e7c44f00f2b2a72ff6dd12158038c` (2026-10-20), which restored the original prompt. `/sharpen` now answers four questions and hands back the rewritten prompt instead of doing the task. Ours is byte-for-byte that text. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the prompt rewrite (what a top professional would add, the rawest material, their methods and tools, one outside check) is poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to it.

## Local changes

1. **Verbatim.** `SKILL.md` is byte-for-byte upstream, frontmatter included. It keeps `disable-model-invocation: true`, so the model never invokes it on its own and `/sharpen` loads it.
2. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
