# amillez model defaults (Claude Code / Cursor Agent CLI / Codex)

Session defaults for **bots and orchestrators**. Every session, review included, starts through Orca with `orca agent launch` and the flags below, on the host picked per [Pick a host](https://github.com/amillez/akit/blob/main/skills/amillez-mode/references/orca-launch.md#pick-a-host). Bots default to `agent-m1` and move to the M4 with `--environment m4` when `agent-m1` is blocked. The full commands are in [Orca launches](https://github.com/amillez/akit/blob/main/skills/amillez-mode/references/orca-launch.md). Flags verified with Orca 1.4.237 on `agent-m1` as of 2026-10-23.

| Situation | Pick | `orca agent launch` flags |
| --- | --- | --- |
| Very direct / super defined | **Claude Haiku 5.5** · **Max** | `--agent claude --model claude-haiku-5-5 --effort max` |
| General code / some reasoning | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **Grok 4.7** · **xHigh** (Cursor Agent CLI) | `--agent claude --model claude-opus-5-5 --effort high` · `--agent cursor --model grok-4.7-xhigh` |
| UI work | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **Grok 4.7** · **xHigh** (Cursor Agent CLI) | `--agent claude --model claude-opus-5-5 --effort high` · `--agent cursor --model grok-4.7-xhigh` |
| Docs, knowledge, playbook, or policy PRs | **Opus 5.5** · **High**. Claude Code usage **> 70%** → **Grok 4.7** · **xHigh** (Cursor Agent CLI). Haiku is not for docs. | `--agent claude --model claude-opus-5-5 --effort high` · `--agent cursor --model grok-4.7-xhigh` |
| Large-work orchestration (Orca coordinator) | **Opus 5.5** · **xHigh** | `--agent claude --model claude-opus-5-5 --effort xhigh` |
| Large reasoning (non-orch) | **Fable 5.1** · **Medium** → High → xHigh | `--agent claude` with the Fable 5.1 model id |
| Review (PR review, cross-model review of a diff, the review step in babysit or proof) | **GPT 6.1 Sol** · **High** on Codex, read-only, for Claude Code and Grok work alike, when the [Review row](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing) requires one. **Opus 5.5** · **High** on Claude Code, read-only, reviews Codex work. The brief is [code review](https://github.com/amillez/akit/blob/main/skills/amillez-mode/references/code-review.md) | `--agent codex --model gpt-6.1-sol --effort high`, with `--worktree path:<main worktree>` so it runs inside the main agent's Orca worktree session, never a new child worktree · for Codex work `--agent claude --model claude-opus-5-5 --effort high` |

**Claude Code usage > 70%.** Before a Claude Code general-code, UI, or docs launch, check `/usage` (or `/status`) in Claude Code. It shows plan usage for the current window. Above 70% → run that task on the Cursor Agent CLI with **Grok 4.7 xHigh** (`grok-4.7-xhigh`). At or below 70% → Opus 5.5 High.

**Workers** do **not** inherit these defaults blindly. Pick model + effort **per slice** from the policy chooser.

## Hard notes

- Leave **Fast** off unless the human explicitly asks.
- Coding agents are **Claude Code** and the **Cursor Agent CLI** (Grok only). **Codex** runs review only, with one exception. Codex may write raster image edits, such as icons or screenshots, that need its image tooling. Scripted edits with ImageMagick or Python stay in the general-code lane (Opus 5.5 High). Source is the [Codex raster image exception](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#codex-raster-image-exception).
- Never use GPT 5.6 or Opus 5.
- Never start a session with a direct `claude`, `claude -p`, `codex exec`, or `agent -p` call. Orca runs each CLI in a tab that Agustín and every bot can reach.
- Leave `--effort` off the Grok lane, since the effort is part of `grok-4.7-xhigh`. Orca starts `cursor-agent` with `--yolo`.
- Orca tabs run without a sandbox, so a read-only role, such as a reviewer, states read-only in its prompt.
- On `agent-m1`, [amillez-mode](https://github.com/amillez/akit/blob/main/skills/amillez-mode/SKILL.md) and simfleet rules win over Argent's installer rules: respect simfleet device claims, run only the named `xcrun simctl` and `adb -s <serial>` operations, and keep Argent results out of project memory.

## Role labels → harness

| Policy label | Model id | Harness |
| --- | --- | --- |
| Haiku | `claude-haiku-5-5` (Max) | Claude Code. Super defined, mechanical |
| Opus | `claude-opus-5-5` (High; xHigh for Orca coordinator) | Claude Code. General code, UI, plans, orchestration |
| Grok | `grok-4.7-xhigh` | Cursor Agent CLI. Coding fallback when Claude Code usage > 70% |
| Fable | Fable 5.1 (Medium → High/xHigh) | Claude Code. Large reasoning, non-orch |
| Review | `gpt-6.1-sol` (High), read-only | Codex. Reviews Claude Code and Grok work when the Review row requires one. Opus 5.5 High on Claude Code reviews Codex work. The brief is [code review](https://github.com/amillez/akit/blob/main/skills/amillez-mode/references/code-review.md). Writes only under the raster image exception in Hard notes |

Claude Code (Opus 5.5) is the default. The Cursor Agent CLI runs Grok 4.7 xHigh when Claude Code usage is above 70%. Codex runs review only, apart from the raster image exception in Hard notes.

## Install paths

The **amillez plugin** installs this file at **user root** (via `install.sh`, `update-install.sh`, or `/setup-amillez-models`):

- `~/.claude/rules/amillez-models.md` (Claude Code)
- `~/.agents/rules/amillez-models.md` (Codex and shared agents)

Never copy it into project `.claude/rules/` or `.agents/rules/`. Project trees hold project-specific skills (e.g. `verify-*`) and optional teammate mirrors of stack skills, under `.claude/skills/` and `.agents/skills/`.
