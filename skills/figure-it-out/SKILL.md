---
name: figure-it-out
description: "Design an auditable playbook when no narrower one fits: a large migration, an ambitious multi-part change, or work a human reviews after stepping away. Scales rigor to the task, runs a hypothesis loop, and logs decisions via show-me-your-work. Use for /figure-it-out, 'figure it out', a large migration, or when no narrower playbook applies."
disable-model-invocation: true
---

# Figure it out

When the task matches no playbook, design one. The deliverable before any code is the workflow itself: a sequence of phases that scales rigor to the task, runs the scientific method, and leaves a decision trail a human can audit after stepping away.

**Where it sits.** Needs parallel workers → stop and report it. Large work runs as an Orca Run (the [`orchestrate-agents`](../orchestrate-agents/SKILL.md) skill). One agent can own the whole loop but the work is long, cross-cutting, or reviewed after stepping away → this skill.

## Lanes

| Role | Lane | Command |
| --- | --- | --- |
| Second opinion on a one-way-door design | The same prompt on the other model family. Claude Code work asks GPT 6.1 Sol, xHigh on Codex. Codex work asks Opus 5.5, High on Claude Code. | `codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh` or `claude -p --model claude-opus-5-5 --effort high` |
| Delegated unit, very direct, super defined, mechanical (files and success criteria already clear) | GPT 6 Luna, Max | `codex exec -m gpt-6-luna -c model_reasoning_effort=max` |
| Delegated unit, general code, some reasoning | Opus 5.5, High. Claude Code usage above 70% → GPT 6.1 Sol, xHigh | `claude --model claude-opus-5-5 --effort high` or `codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh` |
| Delegated unit, UI work | Opus 5.5, High. Claude Code usage above 70% → GPT 6.1 Sol, High | `claude --model claude-opus-5-5 --effort high` or `codex exec -m gpt-6.1-sol -c model_reasoning_effort=high` |

Check Claude Code usage with `/usage` or `/status` before a Claude Code launch. The lanes follow the [agent use policy](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#default-picks). When the policy changes a lane, the policy wins over this table. Never GPT 5.6 or Opus 5. Feed or close stdin on every `codex exec` (`codex exec … - < brief.md`). An open stdin hangs the run.

## Start

Open a todolist whose first item is to read the principles this skill links: [Prove It Works](../amillez-mode/principles/prove-it-works.md), [Never Block on the Human](../amillez-mode/principles/never-block-on-the-human.md), [Foundational Thinking](../amillez-mode/principles/foundational-thinking.md), [Laziness Protocol](../amillez-mode/principles/laziness-protocol.md), [Separate Before Serializing Shared State](../amillez-mode/principles/separate-before-serializing-shared-state.md), [Sequence Work into Verifiable Units](../amillez-mode/principles/sequence-verifiable-units.md), and [Encode Lessons in Structure](../amillez-mode/principles/encode-lessons-in-structure.md). They add depth. Each phase states the rule it needs. Then add the phases below as todos.

## Phase A: Frame

Ground first, then commit. Don't start the run until you can state:

- The definition of done as a falsifiable predicate ([Prove It Works](../amillez-mode/principles/prove-it-works.md)).
- Scope, quantified: rough units and effort, plus the blockers grounding surfaced.
- The rigor level, biased high. One-way doors and high blast radius get more. Reversible low-stakes steps get less. Rigor is gates and artifacts, not "try harder".

Present the framing and tradeoffs before committing to a long run. Reversible work proceeds ([Never Block on the Human](../amillez-mode/principles/never-block-on-the-human.md)), but a multi-hour run earns one checkpoint.

## Phase B: Design the workflow

Decompose into atomic, independently-landable units. Sequence riskiest-unknown-first. Scaffold and verification come before features ([Foundational Thinking](../amillez-mode/principles/foundational-thinking.md)).

- Build the verification harness before the work, with the baseline captured from the pre-change state, so the check reads as "old value vs new value".
- For one-way-door design decisions, write the target shape down and get a second opinion. Send the same prompt to a subagent on the other model family (see **Lanes**), and stress-test a contested result with the `grill-me` skill. Skip it for mechanical work whose shape is already concrete. A second round over a settled design is over-engineering ([Laziness Protocol](../amillez-mode/principles/laziness-protocol.md)).
- Decide what you delegate. Hand a unit to a subagent on its lane only across a seam, in its own worktree or one at a time in yours ([Separate Before Serializing Shared State](../amillez-mode/principles/separate-before-serializing-shared-state.md)). Don't over-delegate. If the design needs several workers running in parallel, stop and report it per **Where it sits**.
- Write the designed phase list down. That list is what the human reviews.

Then execute the design. Add its steps to the todolist as concrete items, after the Phase C entry and before Phase D. Run each under the Phase C loop discipline, and weave the Phase D log through them, a row as each step lands, rather than saving the whole trail for the end.

## Phase C: Run the loop

Each unit is an experiment. State the hypothesis, make the smallest change, measure against the predicate on the real artifact, keep it if it advanced, revert it if it didn't.
Apply [Sequence Work into Verifiable Units](../amillez-mode/principles/sequence-verifiable-units.md), verifying each unit before starting the next instead of batching checks at the end.

- Verify by inspecting the artifact, never a self-report. When something passes too easily, suspect the observation method before the system.
- Pair delegated work with a judge. If a worker games the gate, reset and harden the contract. If the gate itself is wrong, fix the gate in its own change rather than routing around it.
- A verdict is VERIFIED, NOT VERIFIED, or INCONCLUSIVE. Inconclusive is not a pass. Don't hide a negative.

## Phase D: Keep the audit trail

Log the run per the sibling [`show-me-your-work`](../show-me-your-work/SKILL.md) skill. Open the file instead of calling the Skill tool, since `disable-model-invocation: true` keeps it off the Skill tool's list. Work under this skill is usually ambitious enough to commit the trail so the reviewer can read it in the PR. The trail plus the diff is what lets the human come back and trust the work.

## Phase E: Verify and hand back

Check the whole against the Phase A predicate on the real product, not just the harness. For app surfaces that means Argent or the project's `verify-*` skill. Encode any recurring correction as a gate, a lint rule, a check, or a script ([Encode Lessons in Structure](../amillez-mode/principles/encode-lessons-in-structure.md)). Tear down what the run started. Then open a PR for each landable unit, per the [Opening a PR](../amillez-mode/playbooks/opening-a-pr.md) playbook, and never merge it.

**Reply:** the playbook you designed, the rigor level and why, the decision-trail path with its Attention section, what's verified against the predicate, and what's still open.
