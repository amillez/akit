---
name: setup-amillez-models
description: "Point agents at the amillez model chooser (Luna Max / Sol High / Opus High / Fable) instead of writing a pstack-models rule. Use for /setup-amillez-models, \"configure models\", or as the thin replacement for setup-pstack."
disable-model-invocation: true
---

# Setup amillez models

Thin replacement for pstack's `/setup-pstack`. **Do not** write `~/.cursor/rules/pstack-models.mdc` (or any always-applied pstack role map). Our stack uses a policy chooser, not a per-role Cursor rule file.

## Steps

1. **Open the chooser.** Point the user (and yourself) at [`amillez/ai-eng-practices` → `policies/agent-use-policy.md`](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md):
   - Coding host: **agent-m1** (Claude Code / Codex) primary; Cursor cloud only if agent-m1 is down.
   - Default picks: **Luna Max** (straightforward), **Sol High** (general code), **Opus High** (UI), **Fable** (escalate for large/complex — do not start here).
   - Leave Fast off unless the human asks. Escalate one knob at a time.

2. **Confirm the session pick.** State which model + effort this session should use and why (one sentence). Do not invent freestyle frontier spends outside the chooser.

3. **Optional — verification skill.** If the project has no `verify-*` skill (check `.claude/skills/verify-*/`, `.codex/skills/verify-*/`, and `.cursor/skills/verify-*/` only on Cursor cloud fallback), offer once: generate one with `/create-verification-skill` so agents can drive the app and prove changes. On no, move on.

## Done when

The user knows which policy file owns model choice, which pick applies now, and (if relevant) whether a verification skill was offered. No pstack-models rule was written.
