### Visual parity

**You own pixel-exact equivalence. The baseline is the spec. You do not touch it.** Equivalence is verified by image diff, not by eye.

1. Establish the baseline first, before any migration: a visual regression harness that screenshots the current component across its states, plus the target when matching two implementations. For Expo and React Native, drive a fixed simulator or emulator (same device, OS, scale, appearance, and font size for every run) with Argent and diff with its screenshot-diff skill. Use the project's `verify-<app>` skill to reach each state when the repo has one. No baseline, no parity claim. A blocking prerequisite, not a follow-up.
2. Anti-shortcut clauses, stated and held: no harness modifications, no baseline tampering, no component restructuring to make a diff pass. If the baseline looks wrong, stop and ask, don't edit it.
3. Migrate one component at a time. Parallelize across worktrees, one owner per component ([Separate Before Serializing Shared State](../principles/separate-before-serializing-shared-state.md)), and one simulator per owner so runs never share device state. Shared primitives migrate first as a blocking phase.
4. Verify each component against its baseline via image diff on the matching surface. A nonzero diff is a fail. Investigate the pixel delta: a GPT 6 Luna Max verification session can locate and describe the differing region, but only a zero diff passes. Repeat per component until the diff is zero.
5. Push the baseline, final screenshots, and diff output to the repo's `media` branch, never the PR branch, and link them in the PR.
6. Tear down what you started, then run [Opening a PR](opening-a-pr.md) per component or per safe batch.

**Reply:** components migrated, the diff result for each, the baseline harness location, what's left.
