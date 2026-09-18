# amillez model defaults (Claude Code / Codex)

For **bots and orchestrators** in this project (session defaults):

| Host | Default |
| --- | --- |
| **Claude Code** (agent-m1) | **Opus** · effort **High** (→ **xhigh** for taste / architecture / orchestration) |
| **Codex** (agent-m1) | Follow [`agent-use-policy`](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md) role → harness map (Luna/Sol on Codex; Opus/Fable on Claude when available) |

**Workers** do **not** inherit these defaults blindly. Pick model + effort **per slice** from the policy chooser.

## Hard notes

- Leave **Fast** off unless the human explicitly asks.
- Coding host is **agent-m1** Claude Code + Codex **only**. Do not install Cursor rules or write under `.cursor/`.
- Do **not** write or rely on `pstack-models.mdc` (or any always-applied pstack role map).

## Role labels → harness

| Policy label | On Claude Code | On Codex |
| --- | --- | --- |
| Luna | Skip (use Codex) | Mechanical / visual-verify |
| Sol | Sonnet-class if Codex unavailable | Default general implementation |
| Opus | Default (this file) | Skip for UI/plan/orchestrator when Claude is available |
| Fable | Opus at highest effort, or replan | Skip Cursor-only frontier |

Claude vs Codex chooser: **TBD** (bot orchestrators pick when it lands).

## Install paths

Copy or symlink this file as:

- `.claude/rules/amillez-models.md` (Claude Code project)
- `.agents/rules/amillez-models.md` (Codex / shared agents dir)
- Optional user-global Claude: `~/.claude/rules/amillez-models.md` (only if documented / requested)

Prefer project rules over user-global when the repo has its own stack. Use allowlisted skills under `.claude/skills` / `.agents/skills` / `.codex/skills` only — never `.cursor/skills`.
