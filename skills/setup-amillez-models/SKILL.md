---
name: setup-amillez-models
description: >-
  Use when configuring model picks for this org — thin amillez replacement for
  setup-pstack (policy chooser + install/update Claude/Codex **user** rules
  templates; never write pstack-models.mdc or Cursor rules). Stella: day-one
  wiring for coding bots.
disable-model-invocation: true
---
# Setup amillez models

Thin replacement for pstack's `/setup-pstack`. **Do not** write Cursor rule files (`~/.cursor/rules/*`, `pstack-models.mdc`, `.cursor/`, or any always-applied Cursor role map). Our stack uses a policy chooser + Claude Code / Codex on agent-m1 only.

## Bot designer (Stella)

- Day-one wiring for **coding bots**: point them here (or run it on first touch) so model pick follows `agent-use-policy.md`, not freestyle frontier spends.
- Non-coding bots: skip unless they somehow dispatch coding work.
- After model pick, the optional verify-* offer below is how Stella hooks `/create-verification-skill` without a second prompt.

## Steps

0. **Ensure the amillez plugin pack is on this host (user root).** If the machine lacks the pack (no `~/.amillez-plugin.json` / `~/.agents/amillez-plugin.json`, and missing user rules + `setup-amillez-models` under `~/.claude|~/.agents/skills`), run first:

   ```bash
   # from the agent-skills checkout (or AMILLEZ_SKILLS_ROOT)
   ./scripts/ensure-install.sh
   # thin alias (project path ignored): ./scripts/ensure-project.sh
   ```

   Idempotent: prints `amillez plugin: installed` / `already present` / `updated`. Bots/agents must do this before coding per policy. The plugin installs at **device/user root**, not into project trees. Then continue with model setup below.

1. **Open the chooser.** Point the user (and yourself) at [`amillez/ai-eng-practices` → `policies/agent-use-policy.md`](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md):
   - Coding host: **agent-m1** Claude Code + Codex **only** (no Cursor).
   - Default picks (roles → harness):
     - Very direct / super defined → **GPT 6 Luna Max** (Codex `gpt-6-luna`).
     - General code / some reasoning → **Opus 5.5 High** (Claude Code `claude-opus-5-5`); Claude Code usage > 70% → **GPT 6 Sol xHigh** (Codex `gpt-6-sol`).
     - UI work → **Opus 5.5 High**; Claude Code usage > 70% → **GPT 6 Sol High**.
     - Large-work orchestration (Orca coordinator) → **Opus 5.5 xHigh**.
     - Large reasoning (non-orch) → **Fable 5.1 Medium** → High/xhigh.
     - Skip Cursor-only Composer/Grok lanes.
   - **Claude Code usage > 70%:** check `/usage` (or `/status`) in Claude Code for current-window plan usage; above 70% route general/UI work to Codex GPT 6 Sol. Escalate one knob at a time.

2. **Confirm the session pick.** State which model + effort + harness (Claude Code vs Codex) this session should use and why (one sentence). Do not invent freestyle frontier spends outside the chooser.

3. **Install or update Claude / Codex model rule templates (user-level).** Prefer the template shipped in this pack (`templates/models.md`) over linking only to the GitHub policy file. Offer once (or re-run to refresh):

   | Target | Template | Destination |
   | --- | --- | --- |
   | Claude Code **user** | `templates/models.md` | `~/.claude/rules/amillez-models.md` |
   | Codex / shared agents **user** | `templates/models.md` | `~/.agents/rules/amillez-models.md` |

   Resolve the agent-skills checkout (`~/agent-work/agent-skills`, or the repo that owns this skill). Copy (or re-copy) the template — idempotent update is fine. Do **not** invent a pstack role map. Template sets **bot/orchestrator** defaults (**Opus High** for Claude). Workers still follow the policy chooser. **Never** write Cursor rules, `pstack-models.mdc`, anything under `.cursor/`, or project `.claude/rules/amillez-models.md` / `.agents/rules/amillez-models.md` for the plugin pack (project trees keep project-specific skills only).

   Prefer `./scripts/ensure-install.sh` or `./scripts/update-install.sh` when refreshing the host pack (re-installs skills + re-copies **user** rules + stamp).

4. **Optional — verification skill.** If the project has no `verify-*` skill (check **in-repo** `.claude/skills/verify-*/` and `.agents/skills/verify-*/` only — never `.cursor/skills`), offer once: generate one with `/create-verification-skill` so agents can drive the app and prove changes. On no, move on. Verification skills stay **project-local** (committed), not part of the user-root plugin install.

## Done when

The user knows which policy file owns model choice, which pick applies now, whether Claude/Codex **user** rules templates were installed or updated (and where), and (if relevant) whether a verification skill was offered. No Cursor rules or pstack-models rule was written; amillez plugin rules were not written into project trees.
