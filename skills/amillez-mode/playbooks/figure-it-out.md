### Figure it out

**You own the workflow and its audit trail.** When the task matches no playbook, design one. The deliverable before any code is the workflow itself: a sequence of phases that scales rigor to the task, runs the scientific method, and leaves a decision trail a human can audit after stepping away.

**Where it sits.** Needs parallel workers → Orca (the size gate in `SKILL.md`). One agent can own the whole loop but the work is long, cross-cutting, or reviewed after stepping away → Figure it out.

#### Start

Open a todolist whose first item is to read the Principles section of `SKILL.md`. Then add the phases below as todos.

#### Phase A: Frame

Ground first, then commit. Don't start the run until you can state:

- The definition of done as a falsifiable predicate ([Prove It Works](../principles/prove-it-works.md)).
- Scope, quantified: rough units and effort, plus the blockers grounding surfaced.
- The rigor level, biased high. One-way doors and high blast radius get more. Reversible low-stakes steps get less. Rigor is gates and artifacts, not "try harder".

Present the framing and tradeoffs before committing to a long run. Reversible work proceeds ([Never Block on the Human](../principles/never-block-on-the-human.md)), but a multi-hour run earns one checkpoint.

#### Phase B: Design the workflow

Decompose into atomic, independently-landable units. Sequence riskiest-unknown-first. Scaffold and verification come before features ([Foundational Thinking](../principles/foundational-thinking.md)).

- Build the verification harness before the work, with the baseline captured from the pre-change state, so the check reads as "old value vs new value".
- For one-way-door design decisions, write the target shape down and get a second opinion. Send the same prompt to a subagent on a different model lane (see **Subagents and model lanes** in `SKILL.md`), and stress-test a contested result with `grill-me`. Skip it for mechanical work whose shape is already concrete. A second round over a settled design is over-engineering ([Laziness Protocol](../principles/laziness-protocol.md)).
- Decide what you delegate. Hand a unit to a subagent only across a seam, in its own worktree or one at a time in yours ([Separate Before Serializing Shared State](../principles/separate-before-serializing-shared-state.md)). Don't over-delegate. If the design needs several workers running in parallel, stop and report it for the size gate.
- Write the designed phase list down. That list is what the human reviews.

Then execute the design. Add its steps to the todolist as concrete items, after the Phase C entry and before Phase D. Run each under the Phase C loop discipline, and weave the Phase D log through them, a row as each step lands, rather than saving the whole trail for the end.

#### Phase C: Run the loop

Each unit is an experiment. State the hypothesis, make the smallest change, measure against the predicate on the real artifact, keep it if it advanced, revert it if it didn't.
Apply [Sequence Work into Verifiable Units](../principles/sequence-verifiable-units.md), verifying each unit before starting the next instead of batching checks at the end.

- Verify by inspecting the artifact, never a self-report. When something passes too easily, suspect the observation method before the system.
- Pair delegated work with a judge. If a worker games the gate, reset and harden the contract. If the gate itself is wrong, fix the gate in its own change rather than routing around it.
- A verdict is VERIFIED, NOT VERIFIED, or INCONCLUSIVE. Inconclusive is not a pass. Don't hide a negative.

#### Phase D: Keep the audit trail

Log the run per [show me your work](../references/show-me-your-work.md). Figure it out's work is usually ambitious enough to commit the trail so the reviewer can read it in the PR. The trail plus the diff is what lets the human come back and trust the work.

#### Phase E: Verify and hand back

Check the whole against the Phase A predicate on the real product, not just the harness (Argent or the project's `verify-*` skill for app surfaces). Encode any recurring correction as a gate, a lint rule, a check, or a script ([Encode Lessons in Structure](../principles/encode-lessons-in-structure.md)). Tear down what the run started, then run [Opening a PR](opening-a-pr.md) for each landable unit.

**Reply:** the playbook you designed, the rigor level and why, the decision-trail path with its Attention section, what's verified against the predicate, and what's still open.
