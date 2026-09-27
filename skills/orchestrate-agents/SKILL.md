---
name: orchestrate-agents
description: Size-gate then either skip orchestration (small → one direct Claude Code or Codex agent) or run as the Opus 5.5 xHigh coordinator inside Orca (run-create → task-create → worker-start → check --wait). Every invoked coding agent loads amillez-mode. Use when deciding whether to fan out, writing worker briefs, or driving multi-agent DAG work. Triggers like "generate prompts for other agents", "fan this out", "split this across agents", "parallelize this work", "orchestrate", "orca run".
---

# Orchestrate agents

Docs: [Orca CLI overview](https://www.onorca.dev/docs/cli/overview), [Orca Orchestration](https://www.onorca.dev/docs/cli/orchestration).

## Every coding agent runs amillez-mode

Every coding agent you invoke, a single direct agent or an Orca worker, loads and follows the `amillez-mode` skill ([`../amillez-mode/SKILL.md`](../amillez-mode/SKILL.md)). The brief names it explicitly in its MODE field. A brief that does not name amillez-mode is not ready to send. This holds for integrate and prove workers too, and for every respawn.

## Size gate (do this first)

| Gate | Condition | Action |
| --- | --- | --- |
| **Small** | Single surface or package, one PR, clear blast radius, one focused session | **Skip Orca.** Dispatch one agent directly on the matching lane (see **Model lanes**), with a brief that names amillez-mode. |
| **Large** | Multi-surface, multi-package, parallelizable, multi-PR, multi-session, unclear blast radius, or more than one focused session | You are the **Opus 5.5 xHigh** coordinator **inside Orca**. Decompose into tasks and `worker-start` Claude Code or Codex workers. The coordinator plans, dispatches, and waits. Workers own implement, integrate, and prove. |

One-line rule: needs parallel workers → Orca; one agent can own the whole loop but the work is long, cross-cutting, or reviewed after stepping away → dispatch one agent on amillez-mode's [Figure it out](../amillez-mode/playbooks/figure-it-out.md) playbook, no Orca Run.

Do not collapse big work into one mega agent. Do not over-orchestrate a rename.

## Model lanes

Pick `--agent`, `--model`, and `--effort` per task. These match the lanes in `amillez-mode` ([Subagents and model lanes](../amillez-mode/SKILL.md#subagents-and-model-lanes)).

| Work | Lane | Orca worker flags |
| --- | --- | --- |
| Very direct, defined, mechanical (files and success criteria already clear) | GPT 6 Luna, Max | `--agent codex --model gpt-6-luna --effort max` |
| General code, some reasoning | Opus 5.5, High. Claude Code usage above 70% → GPT 6 Sol, xHigh | `--agent claude --model claude-opus-5-5 --effort high` or `--agent codex --model gpt-6-sol --effort xhigh` |
| UI work | Opus 5.5, High. Claude Code usage above 70% → GPT 6 Sol, High | `--agent claude --model claude-opus-5-5 --effort high` or `--agent codex --model gpt-6-sol --effort high` |
| Large reasoning, gnarly single-agent debugging | Fable 5.1, Medium, then High, then xhigh one step at a time | `--agent claude` with the Fable 5.1 model id |
| Visual proof verification (screenshots, video) | GPT 6 Luna, Max, verification only | `--agent codex --model gpt-6-luna --effort max` |
| Orchestration (the coordinator only) | Opus 5.5, xHigh | `claude --model claude-opus-5-5 --effort xhigh` driving Orca |

Check Claude Code usage with `/usage` (or `/status`) before assigning Claude Code lanes. Never use GPT 5.6 or Opus 5. Never stamp Opus 5.5 xHigh on workers. Coding agents are `claude` or `codex` only, never `--agent cursor`.

## Prerequisites (large only)

1. `orca status --json` succeeds (runtime up).
2. Orchestration enabled: Settings → Experimental.
3. Skills: `orca skills install --skill orca-cli` (or `npx skills add https://github.com/stablyai/orca --skill orca-cli`) and the **orchestration** skill. Refresh with `orca skills get orchestration --full` when flags drift.
4. The amillez plugin is installed (`scripts/ensure-install.sh` in `amillez/agent-skills`) before workers code, so every worker can load amillez-mode.

## Coordinator role

- **Plans, dispatches, and waits.** Decompose, author briefs, `worker-start`, `check --wait`, and route human or gate decisions.
- **Never implements, integrates, or proves.** Product slices, merges of worker branches, conflict resolution, and validation are worker tasks with their own briefs.
- **One writer per checkout.** Never two agents on one checkout (`--worktree current` twice at once is forbidden). Under disk pressure, run workers one at a time with `--worktree current` instead of fanning out.

## The brief

The brief is the product. A vague brief fails quietly, because a worker cannot ask you a question. Every `task-create --spec` carries all of it. A field you cannot fill is a task you have not scoped yet.

```
MODE         Load and follow the amillez-mode skill. Name each principle that shaped a decision.
GOAL         one sentence, the outcome, executable by a stranger with no chat access
SCOPE        paths this task may write; paths it may not; its exclusive worktree or branch
CONTEXT      pointers to files and PRs; upstream reports pasted in full when this task
             depends on them, because workers cannot see siblings
ACCEPTANCE   checkable criteria, one per line
VERIFY       exact commands, or the Argent or project verify-* path, plus known gotchas
TIMEBOX      rough cap on runtime; on expiry, return partial findings and stop rather than run on
FORBIDDEN    no merge, no auto-merge, no PR close, no rebase or force-push outside your own
             branch, no fixes outside scope, plus task-specific bans
REPORT       status, branch, head SHA, PR link, verdict, what you actually ran, proof links,
             teardown status, deviations, suggested follow-ups
STANDING     <the run's standing orders, pasted verbatim>
```

Standing orders are numbered lines, one constraint each (lanes, stack shape, verification bar, forbidden paths, escalation policy). Paste them verbatim into every spawn and every resume, since directives decay across resumes. When you catch yourself restating an instruction, append it to the standing orders before you act.

Size the brief to the task. A one-command task gets the template collapsed to a paragraph that still names amillez-mode, the goal, the scope, the verify command, and the report shape. A dependency is a context relay, not just ordering. Undeclared upstream context makes the worker guess. Missing fields are a refuse-to-spawn condition. Never resume-chain a brief. Respawn fresh with consolidated scope.

## Preferred supervised Orca loop

```bash
orca orchestration run-create --objective "<objective>" --json
orca orchestration task-create --spec "<brief>" --task-title "<slice>" --json
orca orchestration worker-start \
  --task <taskId> \
  --worktree new-child \
  --name <slug> \
  --agent claude \
  --model <opaque-model-id> \
  --effort high \
  --setup run \
  --json
# or sequential under disk pressure:
#   --worktree current   (one worker at a time)

orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 900000 --json
orca orchestration check --ack <deliveryId> --wait --types worker_done,escalation,question --timeout-ms 900000 --json
```

Drive runs with `run-create` and `worker-start`, never `orca orchestration run`, `run-stop`, or `coordinator-start`. Completion is `worker_done` with `--outcome`, taskId, and dispatchId. After accept, `worker-release` (or `worker-retain` for debug).

Runtime ownership and the DAG live in Orca. Prompt text alone is not a substitute for Dispatches.

## Core principle: isolation

Each task owns one unit no other task touches, ideally a separate module, package, or directory with its own build and tests. If the work cannot be cut into disjoint units, sequence it (`--worktree current`, one at a time) instead of faking parallelism.

## Retry by failure mode

Classify a failed or silent worker before any retry. Probe read-only first (`orca orchestration check`, `gh`, pushed branches). Never resume a worker just to check on it.

- **Cap hit or out of memory** (context, usage, or memory limit) → respawn with smaller scope.
- **Network drop** → retry as is.
- **Tool error** → retry on a different lane.
- **Unknown** → retry once.
- **Two retries** → abandon the task and replan around it.

A worker that returns late reconciles against the current branch and PR state before anything is accepted. Salvage unique findings through a fresh task, never a blind merge. Bound your own retries the same way. After a few consecutive tool aborts, write a handoff (what is done, where it lives, the exact command to resume) and stop.

## Procedure (large)

1. Confirm the size gate says large. If small, stop and dispatch one direct agent on its lane with a brief that names amillez-mode.
2. Verify prerequisites (`orca status --json`, Experimental on, skills installed, amillez plugin installed).
3. Scout only enough to decompose. Never implement product work in the coordinator session.
4. Write the standing orders. `run-create`, then cut isolated `task-create` items (P1 vs P2), each with a full brief. Include **integrate** and **prove** as their own worker tasks when needed.
5. Assign `--agent`, `--model`, and `--effort` per task from **Model lanes**.
6. `worker-start` with the disk mode (sequential `current` vs `new-child`).
7. `check --wait` for `worker_done`, escalation, or question. Ack deliveries. Use gates or `ask` for blocking decisions only. Apply **Retry by failure mode** to every failure.
8. Prove before PR. Workers open PRs per amillez-mode's Opening a PR playbook, never merge, and tear down what they started.
9. PR babysits belong to the dispatcher ([agent-dispatch-lifecycle, babysit](https://github.com/amillez/ai-eng-practices/blob/main/playbooks/agent-dispatch-lifecycle.md#babysit-until-merged)). The coordinator does not babysit, merge, or close.

## Output

For **small**: one line. `size gate: small → direct <lane> on <Codex|Claude Code> under amillez-mode; no Orca Run.`

For **large**: the Orca command sequence (run, task, worker, check), the standing orders, and N task briefs in the template above, each with agent, model, effort, and worktree mode.

## Anti-patterns

- Skipping the size gate.
- A brief that does not name amillez-mode, or a worker that runs without it.
- Orca without runtime, Experimental, or skills.
- A mega agent outside Orca for large work.
- Two workers on one checkout.
- `--agent cursor` or any Cursor coding host.
- `orchestration run` instead of `run-create` + `worker-start`.
- Opus 5.5 xHigh on every worker.
- Retrying without classifying the failure, or a third retry of the same task.
- Opening a PR before prove.
- Treating this skill's prompt text as a substitute for Orca Dispatches and `worker_done`.
- The coordinator implementing, integrating, proving, or validating instead of dispatching worker tasks for those steps.
