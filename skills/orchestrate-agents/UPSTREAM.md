# orchestrate-agents upstream

`orchestrate-agents` is first-party. Two sections are adapted from poteto's `poteto-mode` Orchestrate playbook in pstack: **The brief** (the worker brief template and its sizing rules) and **Retry by failure mode**. The size gate, Orca loop, model lanes, and coordinator role are ours.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/poteto-mode/playbooks/orchestrate.md` |
| Pinned commit | `ecc249f1e306fc64ddf83c7bed16cacf7c2239db` (2026-09-25 16:04 -07:00) |
| Version | pstack `0.15.5` |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The same pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit both together.

## Local changes

1. **Brief template.** Upstream fields kept (GOAL, SCOPE, CONTEXT, ACCEPTANCE, VERIFY, TIMEBOX, FORBIDDEN, REPORT, STANDING). Added a MODE field that names amillez-mode. VERIFY points at Argent or the project `verify-*` skill instead of control skills. FORBIDDEN drops `gt` and adds no merge, no auto-merge, and no PR close; rebase and force-push are allowed only on the worker's own branch. REPORT adds the PR link, proof links, and teardown status. STANDING is the run's standing orders instead of `preferences.md` in an agent store.
2. **Brief rules.** Kept: the brief is the product, a field you cannot fill is an unscoped task, size the brief to the task, a dependency is a context relay, missing fields refuse the spawn, never resume-chain a brief. Dropped: cloud versus local spawn rules, sub-coordinator briefs, and the sampled brief audit, which assume Cursor cloud agents and the `orch` store.
3. **Retry by failure mode.** Kept verbatim in substance: cap hit or OOM → smaller scope, network drop → as is, tool error → different model (here, a different lane), unknown → once, two retries → abandon and replan. Kept the read-only liveness probe, late-worker reconciliation, and bounding your own retries. Probes use Orca and `gh` instead of the Cursor dashboard and `orch`.
4. **Not ported.** The rest of the playbook (store layout, `orch` CLI, drain protocol, `gt` stacker, ledger, Cursor restart recovery) is Cursor-cloud sized. Orca owns the DAG and runtime state here.
