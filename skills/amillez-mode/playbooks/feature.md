### Feature

**You own the design. Plan, review, verify.** Delegate implementation when the work is big enough to earn it. Stay in the lead.

1. Recon the affected subsystem read-only: entry points, callers, data shapes, tests, and conventions.
2. Plan before you build. Name the data shape and its organizing structure per [Model the Domain](../principles/model-the-domain.md), then the target types, signatures, and module layout, the files in play, risks, and success criteria. Settle empirical open questions (behavior, timing, layout, perf, whether an approach works) with a throwaway [Prototype](prototype.md) now, not after the build. Use the `grill-me` skill only for contested product or preference calls a prototype can't settle. Don't adversarially review the plan while it is still abstract. If the size gate in `SKILL.md` says large, stop and report it for an Orca Run instead of continuing here.
3. Write the throughput checkpoint as four todo items. A dimension that genuinely does not apply (single file, no fan-out) keeps its item with `n/a: <reason>` rather than being dropped:
   - **Blocking first steps.** Gates run before fan-out.
   - **Independent workstreams.** Disjoint files, services, or layers parallelize. Shared writes serialize.
   - **Shared mutable state.** Default to splitting the target ([Separate Before Serializing Shared State](../principles/separate-before-serializing-shared-state.md)). Serialize only for real invariants.
   - **Smallest safe decomposition.** If one worker is best, name why.
4. Build, or delegate code-writing to a subagent on the lane the work needs (see **Subagents and model lanes** in `SKILL.md`), with a specific scope: file paths, the named data shape and its organizing structure (a state machine over scattered booleans, a table or registry over branching, a typed model over repeated shape assumptions), chosen before the delegate writes logic, and success criteria. When the implementation admits multiple valid shapes (error handling, abstraction layer, test structure), name the alternatives in the brief and pick one with a reason. Comments per **Comments** in `SKILL.md`. Surgical edits, re-ground against the source for upstream-derived files. Port shared-primitive improvements to all consumers and verify each. Commit liberally.
5. Verify on the matching surface: Argent for Expo and React Native, the project's `verify-<app>` skill when the repo has one, or the real CLI or service. Visual proof goes to the repo's `media` branch. Inspect each asset against the success criteria and record pass or fail. "Inconclusive" or wrong-surface is not a pass. Flag it.
6. Rebase into small, ordered commits. Stack follow-ups.
   Use [Sequence Work into Verifiable Units](../principles/sequence-verifiable-units.md), building, verifying, and committing each small unit before the next.
7. Tear down what you started, then run [Opening a PR](opening-a-pr.md).

Code-coupled work (one feature, one migration) goes to a single owner with the checkpoint inline. That owner fans out internally after the blocking phase. Fan-out across independent slices (audits, cross-subsystem work, competing experiments) goes through the size gate and Orca, not ad hoc parallel agents. Rewrite the checkpoint at phase boundaries. Start a fresh subagent with consolidated scope rather than chaining interrupts.

**Reply:** what you built, what you chose and why, the throughput checkpoint, open decisions. Tables for design alternatives.
