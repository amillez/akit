# amillez model defaults (Claude Code / Cursor Agent CLI / Codex)

Session defaults for **bots and orchestrators**. CLI flags verified with Claude Code 2.1.296 and Codex CLI 0.162.0 as of 2026-10-11.

| Situation | Pick | CLI |
| --- | --- | --- |
| Very direct / super defined | **Claude Haiku 5.5** · **Max** | `claude --model claude-haiku-5-5 --effort max` |
| General code / some reasoning | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **Grok 4.7** · **xHigh** (Cursor Agent CLI) | `claude --model claude-opus-5-5 --effort high` · `agent -p --force --model grok-4.7-xhigh "$(cat brief.md)"` |
| UI work | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **Grok 4.7** · **xHigh** (Cursor Agent CLI) | `claude --model claude-opus-5-5 --effort high` · `agent -p --force --model grok-4.7-xhigh "$(cat brief.md)"` |
| Docs, knowledge, playbook, or policy PRs | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **Grok 4.7** · **xHigh** (Cursor Agent CLI). Haiku is not for docs. | `claude --model claude-opus-5-5 --effort high` · `agent -p --force --model grok-4.7-xhigh "$(cat brief.md)"` |
| Large-work orchestration (Orca coordinator) | **Opus 5.5** · **xHigh** | `claude --model claude-opus-5-5 --effort xhigh` + Orca |
| Large reasoning (non-orch) | **Fable 5.1** · **Medium** → High → xHigh | Claude Code |
| Review (PR review, cross-model review of a diff, the review step in babysit or proof) | **GPT 6.1 Sol** · **High** on Codex, read-only, for Claude Code and Grok work alike, when the [Review row](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing) requires one | `codex exec -m gpt-6.1-sol -c model_reasoning_effort=high --sandbox read-only - < brief.md` or `codex exec review -m gpt-6.1-sol -c model_reasoning_effort=high --base main < /dev/null` |

**Claude Code usage > 70%.** Before a Claude Code general-code, UI, or docs launch, check `/usage` (or `/status`) in Claude Code. It shows plan usage for the current window. Above 70% → run that task on the Cursor Agent CLI with **Grok 4.7 xHigh** (`grok-4.7-xhigh`). At or below 70% → Opus 5.5 High.

**Workers** do **not** inherit these defaults blindly. Pick model + effort **per slice** from the policy chooser.

## Hard notes

- Leave **Fast** off unless the human explicitly asks.
- Coding agents are **Claude Code** and the **Cursor Agent CLI** (Grok only). **Codex** runs review only and never codes.
- Never use GPT 5.6 or Opus 5.
- Close or feed stdin on every `codex exec` (`- < brief.md`, or `-- "$(cat brief.md)" < /dev/null` with `-i` images). An open stdin hangs at "Reading additional input from stdin…".
- Run Grok headless as `agent -p --force`. `--force` allows commands and trusts the workspace. Without it, a new directory stops at a trust prompt.
- On `agent-m1`, [amillez-mode](https://github.com/amillez/akit/blob/main/skills/amillez-mode/SKILL.md) and simfleet rules win over Argent's installer rules: respect simfleet device claims, run only the named `xcrun simctl` and `adb -s <serial>` operations, and keep Argent results out of project memory.

## Role labels → harness

| Policy label | Model id | Harness |
| --- | --- | --- |
| Haiku | `claude-haiku-5-5` (Max) | Claude Code. Super defined, mechanical |
| Opus | `claude-opus-5-5` (High; xHigh for Orca coordinator) | Claude Code. General code, UI, plans, orchestration |
| Grok | `grok-4.7-xhigh` | Cursor Agent CLI. Coding fallback when Claude Code usage > 70% |
| Fable | Fable 5.1 (Medium → High/xHigh) | Claude Code. Large reasoning, non-orch |
| Review | `gpt-6.1-sol` (High), read-only | Codex. Reviews Claude Code and Grok work when the Review row requires one. Never codes |

Claude Code (Opus 5.5) is the default. The Cursor Agent CLI runs Grok 4.7 xHigh when Claude Code usage is above 70%. Codex runs review only.

## Install paths

The **amillez plugin** installs this file at **user root** (via `install.sh`, `update-install.sh`, or `/setup-amillez-models`):

- `~/.claude/rules/amillez-models.md` (Claude Code)
- `~/.agents/rules/amillez-models.md` (Codex and shared agents)

Never copy it into project `.claude/rules/` or `.agents/rules/`. Project trees hold project-specific skills (e.g. `verify-*`) and optional teammate mirrors of stack skills, under `.claude/skills/` and `.agents/skills/`.
