---
name: orchestrate-agents
description: Size-gate then either skip orch (small → direct Claude/Codex agent) or run as Opus 5.5 xhigh coordinator inside Orca (run-create → task-create → worker-start → check --wait). Use when deciding whether to fan out, generating isolated worker specs, or driving multi-agent DAG work. Triggers like "generate prompts for other agents", "fan this out", "split this across agents", "parallelize this work", "orchestrate", "orca run".
---

# Orchestrate agents (size gate + Orca + Opus 5.5 xhigh)

Docs: [Orca CLI overview](https://www.onorca.dev/docs/cli/overview) · [Orca Orchestration](https://www.onorca.dev/docs/cli/orchestration).

## Size gate (do this first)

| Gate | Condition | Action |
| --- | --- | --- |
| **Small** | Single surface/package, one PR, clear blast radius, one focused session | **Skip Orca.** Dispatch the corresponding agent directly (GPT 6 Luna Max on Codex; Opus 5.5 High on Claude Code, or GPT 6 Sol on Codex when Claude Code usage > 70%). |
| **Needs orch (large)** | Multi-surface, multi-package, parallelizable, multi-PR, multi-session, unclear blast radius, or more than one focused session | You are the **Opus 5.5 xhigh** coordinator **inside Orca**. Decompose into tasks and `worker-start` Claude/Codex workers. **Delegate all work** — implementation, integrate, prove/validate — to workers. Coordinator only plans, dispatches, waits, and routes decisions. |

**Lesson:** do not collapse big work into one mega-agent; do not over-orchestrate a rename.

## Prerequisites (large only)

1. `orca status --json` succeeds (runtime up).
2. Orchestration enabled: Settings → Experimental.
3. Skills: `orca skills install --skill orca-cli` (or `npx skills add https://github.com/stablyai/orca --skill orca-cli`) and the **orchestration** skill; refresh with `orca skills get orchestration --full` when flags drift.
4. Amillez plugin ensured on the project path before workers code.
5. Coding agents are **claude** or **codex** only — never `--agent cursor`.

## Coordinator identity

- **Label:** **Opus 5.5 xhigh** (prefer this name; was Fable 5.1 High).
- **Host:** `agent-m1` Claude Code (`claude --model claude-opus-5-5 --effort xhigh`), driving Orca CLI.
- **Workers:** `--agent claude|codex` + `--model` + `--effort` **per slice** from the chooser (e.g. `--agent codex --model gpt-6-luna --effort max`, `--agent claude --model claude-opus-5-5 --effort high`, or `--agent codex --model gpt-6-sol --effort xhigh` when Claude Code usage > 70%) — not all Opus xhigh. Workers own implement / integrate / prove; coordinator does not.
- **Coordinator does not code product slices, integrate, or validate** — only decompose, dispatch, wait, and route human/gate decisions.
- **Disk:** sequential / max 2 parallel worktrees under pressure; never two agents on one checkout (`--worktree current` twice is forbidden).

## Preferred supervised Orca loop

```bash
orca orchestration run-create --objective "<objective>" --json
orca orchestration task-create --spec "<isolated spec>" --task-title "<slice>" --json
orca orchestration worker-start \\
  --task <taskId> \\
  --worktree new-child \\
  --name <slug> \\
  --agent claude \\
  --model <opaque-model-id> \\
  --effort high \\
  --setup run \\
  --json
# or sequential under disk pressure:
#   --worktree current   (one worker at a time)

orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 900000 --json
orca orchestration check --ack <deliveryId> --wait --types worker_done,escalation,question --timeout-ms 900000 --json
```

Do **not** use retired `orca orchestration run` / `run-stop` / `coordinator-start`. Completion is `worker_done` with `--outcome` + taskId + dispatchId. After accept: `worker-release` (or `worker-retain` for debug).

This skill also helps write isolated task specs (shared context + per-task blocks). **Runtime ownership and the DAG live in Orca** — prompt text alone is not a substitute for Dispatches.

## Core principle: isolation

Each task owns ONE unit no other task touches, ideally a separate module/package/directory with its own build + tests. If the work cannot be cut into disjoint units, sequence it (`--worktree current` one at a time) instead of faking parallelism.

## Procedure (large / needs orch)

1. Confirm size gate → large. If small, stop and recommend direct Luna / Opus 5.5 (or Sol when Claude Code usage > 70%).
2. Verify prerequisites (`orca status --json`, Experimental on, skills installed).
3. Scout only enough to decompose; never implement product work in the coordinator session.
4. `run-create`, then cut isolated `task-create` items (P1 vs P2) — include **integrate** and **prove/validate** as their own worker tasks when needed (not coordinator work).
5. Assign `--agent` / `--model` / `--effort` per task from the chooser.
6. `worker-start` with disk mode (sequential current vs ≤2 new-child).
7. `check --wait` for `worker_done` / escalation / question; ack deliveries; use gates/`ask` for blocking decisions only.
8. Do **not** integrate or validate in the coordinator — dispatch worker tasks for merge/integrate and for prove (prove-before-PR; sim mutex / max 2 sims on agent-m1).
9. Hand PR babysit back to the eng bot (Grok). Grok does not replace Orca for the DAG.

## Output

For **small**: one line — `size gate: small → direct <GPT 6 Luna|Opus 5.5|GPT 6 Sol> on <Codex|Claude Code>; no Orca Run.`

For **large**: the Orca command sequence (run/task/worker/check) plus SHARED CONTEXT and N TASK specs (each with agent/model/effort/worktree mode).

## Anti-patterns

- Skipping the size gate.
- Orca without runtime / Experimental / skills.
- Mega-agent outside Orca for large work.
- Two workers on one checkout; >2 parallel trees under disk pressure without an explicit raise.
- `--agent cursor` or any Cursor coding host.
- Retired `orchestration run` instead of `run-create` + `worker-start`.
- Stamping Opus 5.5 xhigh on every worker.
- Opening a PR before prove.
- Treating this skill's prompt text as a substitute for Orca Dispatches / `worker_done`.
- Coordinator integrating, proving, or validating instead of dispatching worker tasks for those steps.
