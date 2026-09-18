---
name: setup-amillez-models
description: >-
  Use when configuring model picks for this org — thin amillez replacement for
  setup-pstack (policy chooser + install/update Claude/Codex rules templates;
  never write pstack-models.mdc or Cursor rules). Stella: day-one wiring for
  coding bots.
disable-model-invocation: true
---
# Setup amillez models

Thin replacement for pstack's `/setup-pstack`. **Do not** write Cursor rule files (`~/.cursor/rules/*`, `pstack-models.mdc`, `.cursor/`, or any always-applied Cursor role map). Our stack uses a policy chooser + Claude Code / Codex on agent-m1 only.

## Bot designer (Stella)

- Day-one wiring for **coding bots**: point them here (or run it on first touch) so model pick follows `agent-use-policy.md`, not freestyle frontier spends.
- Non-coding bots: skip unless they somehow dispatch coding work.
- After model pick, the optional verify-* offer below is how Stella hooks `/create-verification-skill` without a second prompt.

## Steps

0. **Ensure the amillez plugin pack is on this project.** If the project is new or lacks the pack (no `.amillez-plugin.json` stamp, and missing rules + `setup-amillez-models` skill links), run first:

   ```bash
   # from the agent-skills checkout (or AMILLEZ_SKILLS_ROOT)
   ./scripts/ensure-project.sh /path/to/project
   ```

   Idempotent: prints `amillez plugin: installed` / `already present` / `updated`. Bots/agents must do this before coding per policy. Then continue with model setup below.

1. **Open the chooser.** Point the user (and yourself) at [`amillez/ai-eng-practices` → `policies/agent-use-policy.md`](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md):
   - Coding host: **agent-m1** Claude Code + Codex **only** (no Cursor).
   - Default picks (roles → harness): **Luna Max** Codex (straightforward), **Sol High** Codex (general code), **Opus High** Claude Code (UI / plans), **Fable** → Opus xhigh Claude Code (escalate — do not start here). Skip Cursor-only Composer/Grok lanes.
   - Claude vs Codex chooser TBD. Escalate one knob at a time.

2. **Confirm the session pick.** State which model + effort + harness (Claude Code vs Codex) this session should use and why (one sentence). Do not invent freestyle frontier spends outside the chooser.

3. **Install or update Claude / Codex model rule templates.** Prefer the template shipped in this pack (`templates/models.md`) over linking only to the GitHub policy file. Offer once (or re-run to refresh):

   | Target | Template | Destination |
   | --- | --- | --- |
   | Claude Code project | `templates/models.md` | `.claude/rules/amillez-models.md` |
   | Codex / shared agents | `templates/models.md` | `.agents/rules/amillez-models.md` |
   | Claude user-global (optional) | `templates/models.md` | `~/.claude/rules/amillez-models.md` |

   Resolve the agent-skills checkout (`~/agent-work/agent-skills`, or the repo that owns this skill). Copy (or re-copy) the template — idempotent update is fine. Do **not** invent a pstack role map. Template sets **bot/orchestrator** defaults (**Opus High** for Claude). Workers still follow the policy chooser. **Never** write Cursor rules, `pstack-models.mdc`, or anything under `.cursor/`.

   Prefer `./scripts/ensure-project.sh /path/to/project` (or `update-project.sh`) when refreshing an already-linked project (re-links skills + re-copies rules).

4. **Optional — verification skill.** If the project has no `verify-*` skill (check `.claude/skills/verify-*/` and `.codex/skills/verify-*/` only — never `.cursor/skills`), offer once: generate one with `/create-verification-skill` so agents can drive the app and prove changes. On no, move on.

## Done when

The user knows which policy file owns model choice, which pick applies now, whether Claude/Codex rules templates were installed or updated (and where), and (if relevant) whether a verification skill was offered. No Cursor rules or pstack-models rule was written.
