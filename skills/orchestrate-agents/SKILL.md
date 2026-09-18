---
name: orchestrate-agents
description: Size-gate then either skip orch (small → direct agent) or run as Fable 5.1 High orchestrator that decomposes big work into isolated worker prompts. Use when deciding whether to fan out, generating prompts for other agents, splitting across agents, or parallelizing work. Triggers like "generate prompts for other agents", "fan this out", "split this across agents", "parallelize this work", "orchestrate".
---

# Orchestrate agents (size gate + Fable 5.1 High)

## Size gate (do this first)

| Gate | Condition | Action |
| --- | --- | --- |
| **Small** | Single surface/package, one PR, clear blast radius, one focused session | **Skip this skill's orch path.** Dispatch the corresponding agent directly (Luna / Sol / Opus from agent-use-policy chooser on Claude Code / Codex). |
| **Needs orch** | Multi-surface, multi-package, parallelizable, multi-PR, multi-session, unclear blast radius, or more than one focused session | You are the **Fable 5.1 High** orchestrator. Decompose, pick workers, integrate. Do **not** implement every slice yourself. |

**Lesson:** do not collapse big work into one mega-agent; do not over-orchestrate a rename.

## Orchestrator identity

- **Label:** **Fable 5.1 High** (prefer this name in prompts and reports).
- **Host:** `agent-m1` Claude Code (Fable-class model at **High** effort). If the harness only exposes Opus as nearest: map **Fable 5.1 High** → Claude Code Fable/Opus-equivalent at High — still say Fable 5.1 High.
- **Workers:** model + effort **per slice** from the chooser (Luna Max / Sol High / Opus High→xhigh) — **not** all Fable.
- **Disk:** max 2 parallel worktrees; never parallel agents on one checkout; under disk pressure prefer sequential workers on one shared tree.

You are the leader for needs-orch work. Split into independent chunks, write a stand-alone prompt for each, and integrate the results yourself. Fresh agents have ZERO context, so every prompt must work alone.

## Core principle: isolation

Each task owns ONE unit no other task touches, ideally a separate module/package/directory with its own build + tests. Parallel agents editing the same files collide; agents editing disjoint packages do not. If the work cannot be cut into disjoint units, it is not ready to fan out — scope it down or sequence it instead.

## Procedure (needs orch only)

1. **Confirm the size gate** said needs-orch. If small, stop and recommend a direct Luna/Sol/Opus dispatch instead.
2. **Scout before you fan out.** Map the codebase and discover the real work-list first (list the files, call sites, modules). Never decompose blind. Usual shape: scout inline, then fan out over what you found.
3. **Cut into isolated tasks.** One task per package/dir/feature. Prefer package-level cuts (independent `swift test`/build, or the equivalent) for clean parallelism. Rank P1 (do now, high value, validatable immediately) vs P2 (optional, blind-to-hardware, or lower value), and flag rework risk.
4. **Assign model + effort per slice** from the agent-use-policy chooser. Do not stamp Fable 5.1 High on every worker.
5. **Write ONE shared-context block**, prepended to every task: what the project is, the repo path, how to build + test, the hard rules (what NOT to edit, style conventions), and what "done" means (build + tests green, report the interface).
6. **Write each task block** with: the single location it owns; the goal; PRECISE specs (exact signatures, byte offsets, file paths, data-fixture locations, expected values); the validation it must run; the assigned model/effort/harness; and the line "work only inside <location>, do not touch other modules, vendored code, or the app target, the leader integrates later."
7. **Mark intentional/experimental work** so agents do not "fix" deliberate behavior (gated candidates, known limitations, single-sample validation).
8. **Require a reported interface.** End each task with "report what you built, the public API/types other code should call, and how you validated it." You need these to integrate.
9. **Integrate yourself.** When agents report, read their interfaces, wire the pieces together in a dedicated pass, and run the full build + tests. Integration is never a parallel task; neither is hardware-in-the-loop validation. Prove-before-PR; sim mutex / max 2 concurrent sims on agent-m1.

## Output

For **small**: one line — "size gate: small → direct \<Luna|Sol|Opus\> on \<Codex|Claude Code\>; skip orch."

For **needs orch**: a SHARED CONTEXT block plus N copy-pasteable TASK blocks (each with model/effort/harness). Tell the user to open one chat per task and paste shared-context + that one task. Say which to run now vs optionally; note sequential-on-one-tree vs ≤2 worktrees.

## Anti-patterns

- Skipping the size gate (mega-agent for everything, or orch for a rename).
- Fanning out before the work-list is known.
- Two tasks that edit the same file/dir (guaranteed conflict).
- Parallel workers sharing one working tree.
- A prompt that assumes prior conversation (the agent has none).
- Vague specs ("improve X") instead of exact offsets/signatures/criteria.
- Treating integration or device/hardware validation as a parallel task.
- Stamping Fable 5.1 High on every worker.
- Opening a PR before prove.
