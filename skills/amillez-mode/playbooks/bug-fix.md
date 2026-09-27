### Bug fix

**You own this task. Plan, review, verify.** Delegate investigation and the fix to subagents when the work is big enough to earn them. Stay in the lead.

Be scientific. Every shipped line traces to runtime evidence. Belt-and-suspenders that "might help" is a hypothesis, not a fix. It does not ship. When evidence refutes a hypothesis, revert what it motivated. The smallest change the evidence justifies ships, nothing more.

0. When the input is a report or a thread (an issue, a chat thread, user feedback), restate the underlying issue in plain words before any code: what the user did, what they expected, what happened instead, and what is still unknown. A cause the reporter or launcher proposes is one hypothesis for step 2, not the premise. Don't adopt it until evidence supports it.
1. Reproduce it yourself on the matching surface: Argent for Expo and React Native, the project's `verify-<app>` skill when the repo has one, or the real CLI or service. Do this even when a debug protocol says to ask the user to reproduce. Ask the user only with a stated, specific reason the surface cannot be reached, and only after driving it as far as it goes. If it won't reproduce directly, synthesize the trigger, tighten conditions, or instrument until it fires.
2. Binary-search the cause. Form the candidate hypotheses, then rule them out until one survives. Seed them with read-only recon of the affected subsystem and `git log` / `git bisect` for regression history. Each pass, take the split that cuts the most remaining problem space, get runtime evidence, eliminate. When program state is unclear, add instrumentation or logging and read it as the code runs. Don't guess. Confirm the surviving *mechanism* with runtime evidence before planning the fix.
3. Plan the fix. If it crosses a function boundary, write the target shape (types, signatures, call graph) before the code. If two loops have already failed, escalate per the lanes in `SKILL.md` (Fable 5.1 for gnarly debugging) instead of trying a third guess on the same lane. Delegate implementation to a subagent on the lane the fix needs, with a specific scope.
4. Verify on the same surface. The original repro now passes. "Inconclusive" or wrong-surface is not a pass. Flag it. Unit tests show branch behavior, not bug absence.
5. Stage the commits so the failing repro lands before the fix in git history. Use [tdd](../references/tdd.md) for the failing-test-first cadence when the bug has a cheap local test path. Skip it when the test would be expensive, integration-heavy, or unclear.
   This is the canonical [Sequence Work into Verifiable Units](../principles/sequence-verifiable-units.md) shape: the failing test first and the fix on top.
6. Run [Opening a PR](opening-a-pr.md).

**Reply:** what was broken, root cause, fix, how you verified. Paste failing-then-passing repro output verbatim.
