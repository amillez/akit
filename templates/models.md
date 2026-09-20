# amillez model defaults (Claude Code / Codex)

For **bots and orchestrators** on this host (session defaults):

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

The **amillez plugin** installs this file at **user root** (via `install.sh` / `update-install.sh` / `/setup-amillez-models`):

- `~/.claude/rules/amillez-models.md` (Claude Code user)
- `~/.agents/rules/amillez-models.md` (Codex / shared agents user)

Do **not** copy into project `.claude/rules/` or `.agents/rules/` for the plugin pack. Project trees hold project-specific skills (e.g. `verify-*`) under `.claude/skills` / `.agents/skills` / `.codex/skills` only — never `.cursor/skills`.
