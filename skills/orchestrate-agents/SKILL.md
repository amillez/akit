---
name: orchestrate-agents
description: Decompose a large task into self-contained, isolated prompts for parallel sub-agents (the leader/orchestrator role). Use when work is big enough to split across multiple agents or chats running concurrently and you want copy-pasteable prompts that never collide and integrate cleanly afterward. Triggers like "generate prompts for other agents", "fan this out", "split this across agents", "parallelize this work".
---

# Orchestrate parallel agents

You are the leader. Split a large task into independent chunks, write a stand-alone prompt for each, and integrate the results yourself. Fresh agents have ZERO context, so every prompt must work alone.

## Core principle: isolation
Each task owns ONE unit no other task touches, ideally a separate module/package/directory with its own build + tests. Parallel agents editing the same files collide; agents editing disjoint packages do not. If the work cannot be cut into disjoint units, it is not ready to fan out, scope it down or sequence it instead.

## Procedure
1. **Scout before you fan out.** Map the codebase and discover the real work-list first (list the files, call sites, modules). Never decompose blind. Usual shape: scout inline, then fan out over what you found.
2. **Cut into isolated tasks.** One task per package/dir/feature. Prefer package-level cuts (independent `swift test`/build, or the equivalent) for clean parallelism. Rank P1 (do now, high value, validatable immediately) vs P2 (optional, blind-to-hardware, or lower value), and flag rework risk.
3. **Write ONE shared-context block**, prepended to every task: what the project is, the repo path, how to build + test, the hard rules (what NOT to edit, style conventions), and what "done" means (build + tests green, report the interface).
4. **Write each task block** with: the single location it owns; the goal; PRECISE specs (exact signatures, byte offsets, file paths, data-fixture locations, expected values); the validation it must run; and the line "work only inside <location>, do not touch other modules, vendored code, or the app target, the leader integrates later."
5. **Mark intentional/experimental work** so agents do not "fix" deliberate behavior (gated candidates, known limitations, single-sample validation).
6. **Require a reported interface.** End each task with "report what you built, the public API/types other code should call, and how you validated it." You need these to integrate.
7. **Integrate yourself.** When agents report, read their interfaces, wire the pieces together in a dedicated pass, and run the full build + tests. Integration is never a parallel task; neither is hardware-in-the-loop validation.

## Output
A SHARED CONTEXT block plus N copy-pasteable TASK blocks. Tell the user to open one chat per task and paste shared-context + that one task. Say which to run now vs optionally.

## Anti-patterns
- Fanning out before the work-list is known.
- Two tasks that edit the same file/dir (guaranteed conflict).
- A prompt that assumes prior conversation (the agent has none).
- Vague specs ("improve X") instead of exact offsets/signatures/criteria.
- Treating integration or device/hardware validation as a parallel task.
