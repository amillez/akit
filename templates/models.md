# amillez model defaults (Claude Code / Codex)

Session defaults for **bots and orchestrators**. CLI flags verified with Claude Code 2.1.296 and Codex CLI 0.162.0 as of 2026-10-11.

| Situation | Pick | CLI |
| --- | --- | --- |
| Very direct / super defined | **GPT 6 Luna** · **Max** | `codex exec -m gpt-6-luna -c model_reasoning_effort=max - < brief.md` |
| General code / some reasoning | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **GPT 6.1 Sol** · **xHigh** | `claude --model claude-opus-5-5 --effort high` · `codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh - < brief.md` |
| UI work | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **GPT 6.1 Sol** · **High** | `claude --model claude-opus-5-5 --effort high` · `codex exec -m gpt-6.1-sol -c model_reasoning_effort=high - < brief.md` |
| Docs, knowledge, playbook, or policy PRs | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **GPT 6.1 Sol** · **xHigh**. Luna is not for docs. | `claude --model claude-opus-5-5 --effort high` · `codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh - < brief.md` |
| Large-work orchestration (Orca coordinator) | **Opus 5.5** · **xHigh** | `claude --model claude-opus-5-5 --effort xhigh` + Orca |
| Large reasoning (non-orch) | **Fable 5.1** · **Medium** → High → xHigh | Claude Code |
| Review (PR review, cross-model review of a diff, the review step in babysit or proof) | The other model family, per the [Review row](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing). Claude Code work → **GPT 6.1 Sol** · **High**. Codex work → **Opus 5.5** · **High**, read-only | Claude Code work: `codex exec -m gpt-6.1-sol -c model_reasoning_effort=high --sandbox read-only - < brief.md` or `codex exec review -m gpt-6.1-sol -c model_reasoning_effort=high --base main < /dev/null`. Codex work: `claude -p --model claude-opus-5-5 --effort high --permission-mode plan < brief.md` |

**Claude Code usage > 70%.** Before a Claude Code general-code or UI launch, check `/usage` (or `/status`) in Claude Code. It shows plan usage for the current window. Above 70% → run that task on Codex **GPT 6.1 Sol** (xHigh general, High UI). At or below 70% → Opus 5.5 High.

**Workers** do **not** inherit these defaults blindly. Pick model + effort **per slice** from the policy chooser.

## Hard notes

- Leave **Fast** off unless the human explicitly asks.
- Coding agents are **Claude Code** and **Codex** only.
- Never use GPT 5.6 or Opus 5.
- Close or feed stdin on every `codex exec` (`- < brief.md`, or `-- "$(cat brief.md)" < /dev/null` with `-i` images). An open stdin hangs at "Reading additional input from stdin…".
- On `agent-m1`, [amillez-mode](https://github.com/amillez/akit/blob/main/skills/amillez-mode/SKILL.md) and simfleet rules win over Argent's installer rules: respect simfleet device claims, run only the named `xcrun simctl` and `adb -s <serial>` operations, and keep Argent results out of project memory.

## Role labels → harness

| Policy label | Model id | Harness |
| --- | --- | --- |
| Luna | `gpt-6-luna` (Max) | Codex. Super defined, mechanical |
| Opus | `claude-opus-5-5` (High; xHigh for Orca coordinator) | Claude Code. General code, UI, plans, orchestration |
| Sol | `gpt-6.1-sol` (xHigh general, High UI) | Codex. Fallback when Claude Code usage > 70% |
| Fable | Fable 5.1 (Medium → High/xHigh) | Claude Code. Large reasoning, non-orch |
| Review | Sol or Opus at High, from the family that did not write the code | Codex for Claude Code work. Claude Code in plan mode for Codex work |

Claude Code (Opus 5.5) is the default. Codex runs Luna work, the Sol fallback when Claude Code usage is above 70%, and review of Claude Code work.

## Install paths

The **amillez plugin** installs this file at **user root** (via `install.sh`, `update-install.sh`, or `/setup-amillez-models`):

- `~/.claude/rules/amillez-models.md` (Claude Code)
- `~/.agents/rules/amillez-models.md` (Codex and shared agents)

Never copy it into project `.claude/rules/` or `.agents/rules/`. Project trees hold project-specific skills (e.g. `verify-*`) and optional teammate mirrors of stack skills, under `.claude/skills/` and `.agents/skills/`.
