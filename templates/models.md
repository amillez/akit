# amillez model defaults (Claude Code / Codex)

Session defaults for **bots and orchestrators**. CLI flags verified with Claude Code 2.1.282 and Codex CLI 0.157.0.

| Situation | Pick | CLI |
| --- | --- | --- |
| Very direct / super defined | **GPT 6 Luna** · **Max** | `codex exec -m gpt-6-luna -c model_reasoning_effort=max` |
| General code / some reasoning | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **GPT 6 Sol** · **xHigh** | `claude --model claude-opus-5-5 --effort high` · `codex exec -m gpt-6-sol -c model_reasoning_effort=xhigh` |
| UI work | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **GPT 6 Sol** · **High** | `claude --model claude-opus-5-5 --effort high` · `codex exec -m gpt-6-sol -c model_reasoning_effort=high` |
| Large-work orchestration (Orca coordinator) | **Opus 5.5** · **xHigh** | `claude --model claude-opus-5-5 --effort xhigh` + Orca |
| Large reasoning (non-orch) | **Fable 5.1** · **Medium** → High → xHigh | Claude Code |

**Claude Code usage > 70%.** Before a Claude Code general-code or UI launch, check `/usage` (or `/status`) in Claude Code. It shows plan usage for the current window. Above 70% → run that task on Codex **GPT 6 Sol** (xHigh general, High UI). At or below 70% → Opus 5.5 High.

**Workers** do **not** inherit these defaults blindly. Pick model + effort **per slice** from the policy chooser.

## Hard notes

- Leave **Fast** off unless the human explicitly asks.
- Coding agents are **Claude Code** and **Codex** only.
- Never use GPT 5.6 or Opus 5.

## Role labels → harness

| Policy label | Model id | Harness |
| --- | --- | --- |
| Luna | `gpt-6-luna` (Max) | Codex. Super defined, mechanical, visual verify |
| Opus | `claude-opus-5-5` (High; xHigh for Orca coordinator) | Claude Code. General code, UI, plans, orchestration |
| Sol | `gpt-6-sol` (xHigh general, High UI) | Codex. Fallback when Claude Code usage > 70% |
| Fable | Fable 5.1 (Medium → High/xHigh) | Claude Code. Large reasoning, non-orch |

Claude Code (Opus 5.5) is the default. Codex runs Luna work and the Sol fallback when Claude Code usage is above 70%.

## Install paths

The **amillez plugin** installs this file at **user root** (via `install.sh`, `update-install.sh`, or `/setup-amillez-models`):

- `~/.claude/rules/amillez-models.md` (Claude Code)
- `~/.agents/rules/amillez-models.md` (Codex and shared agents)

Never copy it into project `.claude/rules/` or `.agents/rules/`. Project trees hold project-specific skills (e.g. `verify-*`) and optional teammate mirrors of stack skills, under `.claude/skills/` and `.agents/skills/`.
