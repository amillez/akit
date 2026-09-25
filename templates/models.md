# amillez model defaults (Claude Code / Codex)

For **bots and orchestrators** on this host (session defaults, verified 2026-09-25 on agent-m1: Claude Code 2.1.282, Codex CLI 0.157.0):

| Situation | Pick | CLI |
| --- | --- | --- |
| Very direct / super defined | **GPT 6 Luna** · **Max** | `codex exec -m gpt-6-luna -c model_reasoning_effort=max` |
| General code / some reasoning | **Opus 5.5** · **High** — Claude Code usage **> 70%** → **GPT 6 Sol** · **xHigh** | `claude --model claude-opus-5-5 --effort high` · `codex exec -m gpt-6-sol -c model_reasoning_effort=xhigh` |
| UI work | **Opus 5.5** · **High** — Claude Code usage **> 70%** → **GPT 6 Sol** · **High** | `claude --model claude-opus-5-5 --effort high` · `codex exec -m gpt-6-sol -c model_reasoning_effort=high` |
| Large-work orchestration (needs orch / Orca coordinator) | **Opus 5.5** · **xHigh** | `claude --model claude-opus-5-5 --effort xhigh` + Orca |
| Large reasoning (non-orch) | **Fable 5.1** · **Medium** → High → xhigh | Claude Code |

**Claude Code usage > 70%:** before a Claude Code general-code or UI launch, check `/usage` (or `/status`) in Claude Code — it shows plan usage for the current window. Above 70% → run that task on Codex **GPT 6 Sol** (xHigh general, High UI). At or below 70% → Opus 5.5 High.

**Workers** do **not** inherit these defaults blindly. Pick model + effort **per slice** from the policy chooser.

## Hard notes

- Leave **Fast** off unless the human explicitly asks.
- Coding host is **agent-m1** Claude Code + Codex **only**. Do not install Cursor rules or write under `.cursor/`.
- Do **not** write or rely on `pstack-models.mdc` (or any always-applied pstack role map).

## Role labels → harness

| Policy label | Model id | Harness |
| --- | --- | --- |
| Luna | `gpt-6-luna` (Max) | Codex — super defined / mechanical / visual-verify |
| Opus | `claude-opus-5-5` (High; xHigh for Orca coordinator) | Claude Code — general code, UI, plans, orch |
| Sol | `gpt-6-sol` (xHigh general, High UI) | Codex — fallback when Claude Code usage > 70% |
| Fable | Fable 5.1 (Medium → High/xhigh) | Claude Code — large reasoning, non-orch |

Claude vs Codex: Claude Code (Opus 5.5) by default; Codex for Luna work and for Sol fallback when Claude Code usage > 70%.

## Install paths

The **amillez plugin** installs this file at **user root** (via `install.sh` / `update-install.sh` / `/setup-amillez-models`):

- `~/.claude/rules/amillez-models.md` (Claude Code user)
- `~/.agents/rules/amillez-models.md` (Codex / shared agents user)

Do **not** copy into project `.claude/rules/` or `.agents/rules/` for the plugin pack. Project trees hold project-specific skills (e.g. `verify-*`) under `.claude/skills` / `.agents/skills` / `.codex/skills` only — never `.cursor/skills`.
