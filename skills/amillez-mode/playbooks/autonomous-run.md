### Autonomous run

**You own the exit condition. Define done, then drive to it without stopping.**

1. State the exit condition as a checkable predicate before the first iteration (tests green, repro fixed, all N PRs merge-ready, pixel diff zero). Merge-ready is the ceiling for PR predicates, since only Agustín merges.
2. Pick the wake mechanism. An event to wait on (CI, a review, a merge, a ref advancing) comes from the dispatcher's settle-watch and GitHub listeners, which send you back when it fires. End the iteration with a report that names the event you are waiting on. Work with no external event keeps iterating in the same session. Do not start `/loop`, a background sleep loop, or your own poller.
3. Each iteration makes the smallest change the evidence justifies, verifies it against the predicate, commits if it advanced, and discards changes that didn't help. Belt-and-suspenders that "might help" gets reverted, not left to ride.
   Sequence the work per [Sequence Work into Verifiable Units](../principles/sequence-verifiable-units.md), verifying each unit before the next instead of batching checks at the end.
4. Mid-run discoveries are yours. Address broken skills, related bugs, flaky verifiers, review noise, tooling failures, orphaned follow-ups, and fixable drift yourself under amillez-mode. Put out-of-band fixes in their own small PR ([Opening a PR](opening-a-pr.md)), and a broken skill in its own PR in `amillez/agent-skills`. Do not park reversible work for the human. Surface only the always-pause list, genuine product or preference calls no experiment can settle, or a real dead end. Keep the predicate as the main drive, and return to it after each side fix.
5. Checkpoint every iteration as a row in an inline `decision.tsv` in your notes (iteration, change, predicate before, predicate after, kept or discarded).
6. Stop when the predicate is met. A plateau is not a stop, so keep going and pivot your approach to push past it. Surface a genuine dead end rather than spinning, and never relax the predicate to declare victory.
7. Tear down what the run started (simulators, emulators, Metro and dev servers, Expo CLI processes, watchers), then check that no used Metro port (commonly 8081, 8090) is listening.

**Reply:** the exit condition, iterations run, what landed with PR links, what was discarded, the final predicate state, and teardown status.
