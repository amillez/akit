# figure-it-out upstream

`figure-it-out` is our port of poteto's `figure-it-out` skill from pstack. It is a separate core skill that holds the whole procedure, so `/figure-it-out` runs without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/figure-it-out/` (`SKILL.md`) |
| Compared against | `00b52d954a99ff67802cad428ff19218659f76fd` (pstack `0.15.11`). The directory last changed in `b0b9c7a0baf8b6aa1d00bf77d4101e577d4ba411` (2026-09-23) and is identical on `origin/main` at pstack `0.15.15` (`df581122cde17e6e27686b5a448bde23e4ad4318`). |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the phase structure, rigor scaling, hypothesis loop, and audit-trail hand-back are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Frontmatter.** Kept `name`, the upstream `description` with its `/figure-it-out`, "figure it out", large-migration, and no-narrower-playbook triggers, and `disable-model-invocation: true`, since `/figure-it-out` is explicit-invoke.
2. **Where it sits.** Added a rule after the intro. Needs parallel workers → stop and report it, since large work runs as an Orca Run through the [`orchestrate-agents`](../orchestrate-agents/SKILL.md) skill. One agent can own the whole loop but the work is long, cross-cutting, or reviewed after stepping away → this skill. The same one-line rule is in amillez-mode's size-gate trigger and the `orchestrate-agents` size gate. Upstream's poteto-mode routing (run this even when a narrower playbook fits) is an amillez-mode Non-negotiables trigger.
3. **Start.** "Read the Principles section of the **poteto-mode** skill" → the first todo reads the seven principles this skill links. Each phase states the rule it needs, so the phases hold without opening them.
4. **Lanes.** Added a lane table with launch commands following the [agent use policy](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#default-picks), which wins when it changes a lane. The second opinion on a one-way-door design is the same prompt on the other model family (Opus 5.5 High on Claude Code with `claude -p --model claude-opus-5-5 --effort high`, or GPT 6.1 Sol xHigh on Codex with `codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh`). Delegated units copy amillez-mode's general-code, UI, and Luna Max rows, with the 70% Claude Code usage switch checked with `/usage` or `/status`. Adds the `codex exec` stdin note and the never GPT 5.6 or Opus 5 rule.
5. **Architect and arena.** "Run the **architect** skill (it runs **arena**)" → write the target shape down, send the same prompt to a subagent on the other model family, and stress-test a contested result with `grill-me`. The skip rule for mechanical work and the over-engineering line are kept.
6. **Delegation.** "Decide what fans out" → decide what you delegate. A unit goes to a subagent on its lane only across a seam, in its own worktree or one at a time in the caller's. A design that needs parallel workers stops and is reported per **Where it sits**.
7. **Audit trail.** "The **show-me-your-work** skill" → a link to the sibling [`show-me-your-work`](../show-me-your-work/SKILL.md) skill, opened as a file since `disable-model-invocation: true` keeps it off the Skill tool's list.
8. **Phase E.** Adds Argent or the project's `verify-*` skill for app surfaces, teardown of what the run started, and a PR for each landable unit per amillez-mode's Opening a PR playbook, never merged. The reply line adds the trail's Attention section.
9. **Sibling links.** Principle mentions (`the **<slug>** principle skill`) → relative links into `../amillez-mode/principles/`, and Opening a PR → `../amillez-mode/playbooks/opening-a-pr.md`. The links are optional. amillez-mode is core and installs beside this skill, so they resolve in the repo and after install. The skill never requires loading amillez-mode.
10. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.
