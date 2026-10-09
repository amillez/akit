### Investigation

**You own the answer. Plan, route, write.**

Investigation requests are read-only. They produce a cited explanation or a recommendation, not a code change.

0. When the question arrives as a report or a thread, restate the underlying question in plain words before any recon: what is being asked and what evidence would settle it. An explanation the reporter proposes is a hypothesis to check against the code and history, not the answer.
1. Recon the affected code read-only: entry points, callers, data shapes, tests, and config. For motivation questions ("why was it built this way"), also read the history with `git log -S`, `git blame`, the PRs that introduced the code, and any linked issues or docs. Route bulk reading to a subagent and keep the reduced findings in the main thread ([Guard the Context Window](../principles/guard-the-context-window.md)).
2. Throughput checkpoint stays one line: `throughput checkpoint: n/a, read-only investigation`.
3. Produce the output as Overview / Key Concepts / How It Works / Where Things Live / Gotchas, or a recommendation with a tradeoffs table if the request is a decision between alternatives. Cite a file and line, a commit, or a PR for every claim.
4. Apply the sibling [`unslop`](../../unslop/SKILL.md) skill to the reply.

No PR and no babysit. If the investigation precedes a code change, hand back and re-route to [Bug fix](bug-fix.md) or [Feature](feature.md).

**Reply:** the investigation output. For "are we sure?" answers, include your real judgment with reasons. Push back if the premise is wrong (see Autonomy in `SKILL.md`).
