---
name: setup-amillez-models
description: >-
  Pick the model lane for this session from the agent use policy, and install
  or update the user-level Claude Code and Codex model rules
  (templates/models.md). Use for /setup-amillez-models or when wiring a coding
  bot's model picks on day one.
disable-model-invocation: true
---
# Setup amillez models

Model choice follows the policy chooser in `amillez/ai-eng-practices`. This skill applies it to the session and keeps the user-level model rules current.

## Steps

0. **Ensure the amillez plugin pack is installed at user root.** From the akit checkout (or `AMILLEZ_SKILLS_ROOT`), run:

   ```bash
   ./scripts/ensure-install.sh
   ```

   It is idempotent and prints `amillez plugin: installed`, `already present`, or `updated`. Bots and agents run it before coding per policy. The pack installs at user root, never into project trees. Then continue with model setup below.

1. **Open the chooser.** Point the user (and yourself) at [`amillez/ai-eng-practices` → `policies/agent-use-policy.md`](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md):
   - Coding agents are Claude Code and Codex only.
   - Default picks (roles → harness):
     - Very direct / super defined → **GPT 6 Luna Max** (Codex `gpt-6-luna`).
     - General code / some reasoning → **Opus 5.5 High** (Claude Code `claude-opus-5-5`); Claude Code usage > 70% → **GPT 6 Sol xHigh** (Codex `gpt-6-sol`).
     - UI work → **Opus 5.5 High**; Claude Code usage > 70% → **GPT 6 Sol High**.
     - Large-work orchestration (Orca coordinator) → **Opus 5.5 xHigh**.
     - Large reasoning (non-orch) → **Fable 5.1 Medium** → High/xHigh.
     - Never GPT 5.6 or Opus 5.
   - **Claude Code usage > 70%.** Check `/usage` (or `/status`) in Claude Code for current-window plan usage. Above 70%, route general and UI work to Codex GPT 6 Sol. Escalate one knob at a time.

2. **Confirm the session pick.** State which model + effort + harness (Claude Code vs Codex) this session should use and why (one sentence). Do not invent freestyle frontier spends outside the chooser.

3. **Install or update the user-level model rules.** Prefer the template shipped in this pack (`templates/models.md`) over linking only to the GitHub policy file. Offer once (or re-run to refresh):

   | Target | Template | Destination |
   | --- | --- | --- |
   | Claude Code **user** | `templates/models.md` | `~/.claude/rules/amillez-models.md` |
   | Codex / shared agents **user** | `templates/models.md` | `~/.agents/rules/amillez-models.md` |

   Resolve the akit checkout (`~/agent-work/akit`, or the repo that owns this skill). Copy (or re-copy) the template. The copy is idempotent. The template sets **bot/orchestrator** defaults (**Opus 5.5 High** on Claude Code). Workers still follow the policy chooser. Never copy the template into project `.claude/rules/` or `.agents/rules/`.

   `./scripts/update-install.sh` refreshes the skills, the user rules, and the stamp in one run.

4. **Optional verification skill.** If the project has no `verify-*` skill (check `.claude/skills/verify-*/` and `.agents/skills/verify-*/` in the repo), offer once to generate one with `/create-verification-skill` so agents can drive the app and prove changes. On no, move on. Verification skills are committed in the project, not installed with the plugin.

## Done when

The user knows which policy file owns model choice, which pick applies now, whether the user-level model rules were installed or updated (and where), and (if relevant) whether a verification skill was offered. Nothing was written into project rules directories.
