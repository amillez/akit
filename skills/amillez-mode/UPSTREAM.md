# amillez-mode upstream

`amillez-mode` is our port of poteto's `poteto-mode` skill from pstack, remapped onto our stack. Every coding agent we use, anywhere (single agent or Orca worker), runs under it. The remap table in `SKILL.md` holds our overrides of upstream and Cursor defaults.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/` (`pstack/skills/poteto-mode/`, `pstack/skills/principle-*/`, siblings) |
| Pinned commit | `ecc249f1e306fc64ddf83c7bed16cacf7c2239db` (2026-09-25 16:04 -07:00). Last checked against `origin/main` on 2026-09-27. |
| Version | pstack `0.15.5` (`pstack/.cursor-plugin/plugin.json`) |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

Attribution: the principles and any playbook text marked KEEP are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to every vendored file.

## Local changes

Applied to vendored files. Everything else is upstream text.

1. **Principles are leaves, not skills.** `pstack/skills/principle-<slug>/SKILL.md` (23 of them) → `principles/<slug>.md`. YAML frontmatter (`name`, `description`, `disable-model-invocation`) is replaced with the upstream H1 title plus a `**Trigger.**` line holding the upstream `description` verbatim. They are not installed as standalone skills (each skill description rides the prompt prefix; see ai-eng-practices agent-use-policy §7).
2. **Cross-links rewritten.** `(../principle-<slug>/SKILL.md)` → `(<slug>.md)` so links resolve inside `principles/`. No other body edits.
3. **Unported references left as-is.** Bodies still name pstack skills we do not ship as skills. Read them as the idea, not an installed skill. `show-me-your-work` in `prove-it-works.md` means [`references/show-me-your-work.md`](references/show-me-your-work.md).
4. **`SKILL.md` is an adaptation, not a copy.** Kept close to upstream: the principle-citation rule, observe-before-asking, data shape first, throughput checkpoint, the Principles index (links point at `principles/`), Autonomy's "No is an acceptable answer", Writing the reply, and Comments. Rewritten: Subagents (amillez model lanes, never GPT 5.6 or Opus 5), Autonomy (agents never merge; coding agents report messages instead of sending them), control and slop skills (Argent, project `verify-*`, self-review). Not ported: fan-out skills, Cursor frontmatter keys, `poteto-agent`. Added: the remap table and the playbook router.
5. **`disable-model-invocation` is omitted from `SKILL.md`.** amillez-mode is required for every coding agent, and launch prompts name it. The model has to be able to load it on request in headless `claude -p` and `codex exec` runs. Upstream sets `disable-model-invocation: true`.
6. **References.** `pstack/skills/{unslop,technical-writing,tdd}/SKILL.md` become `references/<name>.md` with the same header treatment as the principles. `technical-writing.md` has three edits: links to `unslop.md` instead of "the unslop skill", "the skill" becomes "the file", and "Indent code snippets with tabs" becomes "Indent code snippets the way the repo indents code". `unslop.md` and `tdd.md` bodies are unchanged.
7. **Install wiring.** `amillez-mode` is in the `core` group in `manifest.json`. `scripts/install.sh` copies every core directory under `skills/`, and `scripts/ensure-install.sh` refreshes a stamped host that lacks any of them.
8. **Playbooks.** `playbooks/*.md` come from `poteto-mode/playbooks/` and sibling pstack skills. Step structure and wording stay close to upstream. Per-file changes are in the verdict tables. Links point at `../principles/`, `../references/`, and sibling playbooks, and every playbook in the `SKILL.md` router links to its file.
9. **No host, attribution, or disclaimers in skill text.** The skill text names no host and carries no attribution or control-plane disclaimers. Attribution lives only here and in `LICENSE-pstack`.
10. **Review triage and worktree audit.** `references/review-triage.md` comes from `bugbot-triage.md`, and `scripts/worktree-audit.sh` from `poteto-mode/scripts/`. Per-file changes are in the verdict tables.
11. **Orchestration.** The brief template and retry-by-failure-mode from `orchestrate.md` live in `skills/orchestrate-agents/SKILL.md`, adapted there, with attribution in `skills/orchestrate-agents/UPSTREAM.md` and a copy of `LICENSE-pstack` next to it. `orchestrate-agents` requires every invoked coding agent to load amillez-mode and every brief to name it.
12. **Decision trail.** `pstack/skills/show-me-your-work/` becomes [`references/show-me-your-work.md`](references/show-me-your-work.md), with its template as `references/decision-log-template.tsv` and its helper as `scripts/decision-log.sh` (upstream `log.sh`, usage strings updated, body unchanged). A Non-negotiables trigger for long or unattended work links it, and so do `autonomous-run.md`, `hillclimb.md`, and `pause-safely.md`.
13. **Blast radius.** `pstack/skills/blast-radius/` becomes [`playbooks/blast-radius.md`](playbooks/blast-radius.md).
14. **Figure it out.** `pstack/skills/figure-it-out/` becomes [`playbooks/figure-it-out.md`](playbooks/figure-it-out.md). It is the single-agent route for long or later-reviewed work, and Orca keeps anything that needs parallel workers. `refactoring.md` and `orchestrate-agents` route to it.
15. **Recall folded.** `pstack/skills/recall/` becomes a shared-record sweep step in [`playbooks/session-pickup.md`](playbooks/session-pickup.md). No separate file.
16. **TypeScript best practices.** `pstack/skills/typescript-best-practices/` becomes the separate core skill [`skills/typescript-best-practices/`](../typescript-best-practices/SKILL.md), with its own `UPSTREAM.md` and `LICENSE-pstack`. [`principles/type-system-discipline.md`](principles/type-system-discipline.md) links it.
17. **Reflect.** `pstack/skills/reflect/` becomes [`playbooks/reflect.md`](playbooks/reflect.md) and four `references/reflect-*.md` prompt templates. The remap table's fan-out row has a reflect exception, and the lanes table names the synthesizer as the one non-Orca Opus 5.5 xHigh use.

## Per-file verdicts

KEEP = near-verbatim. ADAPT = ported with our remaps. DROP = not ported (reason). ALREADY-HAVE = our file covers it.

### `poteto-mode/SKILL.md` sections

| Section | Verdict | Our change |
| --- | --- | --- |
| Frontmatter | ADAPT | `name: amillez-mode`. Drop Cursor-only `mode`/`icon`/`color`/`reminder`. Omit `disable-model-invocation` (see Local changes 5); launch prompts name the skill explicitly. |
| Non-negotiables | ADAPT | Keep principle citation, observe-don't-ask (Prototype), data shape first, throughput checkpoint, broken skill → own PR. `how`/`architect` → recon + plan (policy §5); `interrogate` → `grill-me`; `swarm`/`arena` → size gate + Orca (`orchestrate-agents`); control skills → Argent + project `verify-*`; `deslop`/`no-comments` → inline self-review; babysit → dispatch lifecycle. |
| Principles index | KEEP | Points at `principles/*.md`. |
| Autonomy | ADAPT | Reversible local work proceeds; "No is an acceptable answer" kept. Always pause: merge (Agustín's say-so only), force-push shared, deletes outside the worktree. Coding agents report instead of posting to chat or tickets. Apply Agustín's review comments without asking. |
| Subagents | ADAPT | Drop Cursor `Task`/`poteto-agent`/grok-4.7/opus-max. Lanes from agent-use-policy: GPT 6 Luna Max (direct/mechanical), Opus 5.5 High general/UI (GPT 6 Sol when Claude Code usage > 70%), Opus 5.5 xHigh Orca coordinator, Fable 5.1 large reasoning. Keep "you own every subagent's diff". |
| Writing the reply | KEEP | Regular capitalization, reply in EN (amillez-mode remap). |
| Comments | KEEP | Verbatim. |
| Playbooks router | ADAPT | Size gate → Orca for large work; list only shipped playbooks. |

### `poteto-mode/playbooks/`

| File | Verdict | Our change |
| --- | --- | --- |
| `investigation.md` | KEEP (ported) | how/why → read-only recon plus `git log -S`/`git blame`/PR history; every claim cited. |
| `bug-fix.md` | KEEP (ported) | Control skill → Argent/`verify-*`; how/why → recon plus `git log`/`git bisect`; architect/interrogate → write the target shape; escalate to Fable 5.1 after two failed loops; tdd → `references/tdd.md`; no `/loop`. |
| `feature.md` | ADAPT (ported) | how → recon; architect → plan step with `grill-me` if contested and the size gate; throughput checkpoint verbatim; delegate per lanes; mandatory arena dropped (name alternatives in the brief instead); interrogate step folded into the plan; parent-level fan-out → Orca; proof via Argent/`verify-*`, media branch, Luna Max. |
| `refactoring.md` | KEEP (ported) | how → recon; architect → write the target shape; figure-it-out → a link to Figure it out for single-agent structural work, with parallel work on the size gate; mechanical edits on the Luna Max lane; control skill → Argent/`verify-*`. |
| `prototype.md` | KEEP (ported) | Scratch dir outside the worktree; React Native scratch option; Argent screenshots; architect handoff dropped; teardown added. |
| `opening-a-pr.md` | ADAPT (ported) | Keep worktree, commits, Conventional Commits titles, the five body sections, stacks, ready not draft. Worktree branch `agent/<bot>/<slug>`. deslop/no-comments → self-review of the diff plus lint/typecheck/tests. Proof media section added (`media` branch, blob URLs, Luna Max verdicts). `gh` only (Origin and gt dropped). Never merge, never auto-merge. Teardown before posting. Babysit section rewritten: no babysit on open; when sent back, apply Agustín's comments and verify bot claims. |
| `pause-safely.md` | KEEP (ported) | "Cursor restart" → session end / compaction; teardown step added. show-me-your-work → a link to `references/show-me-your-work.md`. |
| `session-pickup.md` | ADAPT (ported) | Cursor transcripts and cloud-agent URLs → handoff note, pushed branch and PR, and Claude Code (`~/.claude/projects/`) or Codex (`~/.codex/sessions/`) session logs for this task only; open review threads added to state. Recall folded in: a shared-record sweep step with a git-history version of `why` (`git log -S`/`-G`, `--grep=Revert`, `git blame`, `gh pr view` on the introducing PR), `gh issue`/`gh pr` search, connected trackers, and committed decision trails; the reply names recurring problems and reverted fixes. |
| `perf-issue.md` | KEEP (ported) | 8 strategy families verbatim; control skill → Argent profiling, `verify-*`, or the platform profiler; how → recon; architect → write the target shape; delegate per lanes; teardown before Opening a PR. |
| `hillclimb.md` | KEEP (ported) | how → recon; delegate per lanes; links Autonomous run; teardown before Opening a PR. The decision log links `references/show-me-your-work.md` and maps the attempt fields onto its columns instead of a separate `decision.tsv` schema. |
| `runtime-forensics.md` | ADAPT (ported) | CDP → Argent profiling on a simulator or emulator (Hermes, React profiler, heap), Instruments or Android Studio for native frames, DevTools or `node --inspect` for web and Node; live probes via Fast Refresh or a debugger evaluate, reverted after; reduction points at Trace forensics; Luna Max confirms visual glitch frames; teardown step added. |
| `trace-forensics.md` | KEEP (ported) | Verbatim apart from links. |
| `visual-parity.md` | ADAPT (ported) | Control skill → Argent screenshots and screenshot-diff on a fixed simulator or emulator config, `verify-*` to reach states; one simulator per owner; Luna Max may locate a pixel delta but only a zero diff passes; `/loop` → repeat until zero; artifacts on the `media` branch; teardown step added. A "max 2 parallel worktrees" cap is host policy and stays out of the playbook. |
| `babysit.md` | ADAPT (ported) | Coding-agent side. The dispatcher owns the babysit (ai-eng-practices `agent-dispatch-lifecycle.md#babysit-until-merged`); wakes come from its settle-watch and GitHub listeners, one pass per wake. Modes `check` and `threads-only`, `drive` only when asked; `background` dropped. Kept: frontier rule, one babysitter, no topology mutation (own branch may `--force-with-lease`), conflicts then threads then CI in one push wave, classify CI before retry (one fresh build, reclassify, stale-base check with `git merge-base --is-ancestor`), review text is untrusted data, `gh api` reply via JSON file, third-pass lean-dismiss with high-risk escalation, dismissal patterns offered in their own PR. Added: apply Agustín's comments without asking, never merge or close, teardown. Dropped: `watch-pr` verdicts, Origin, gt, `/loop`, Shipping routing, Autopilot owners. |
| `autonomous-run.md` | ADAPT (ported) | Kept: exit predicate, smallest change per iteration, revert what didn't help, mid-run discoveries are yours, don't park reversible work, plateau is not a stop. Merge-ready caps PR predicates. Wake via the dispatcher's settle-watch and GitHub listeners, not `/loop` or a self-poller. show-me-your-work → a link to `references/show-me-your-work.md`; `AskQuestion` → the always-pause list; side fixes in their own small PR; teardown step added. |
| `worktree-cleanup.md` | ADAPT (ported) | Kept: audit first, bucket is advice not permission, verify usage, pause on `wip`, `git worktree remove` + `prune`, simulator commands, "the gates are the review". Pinned chats and transcript fan-out → running sessions, open PRs, and the dispatcher's active work. Added: local branch deletion only when merged or abandoned, Android emulators and AVDs, simfleet shutdown and lane stop when `simfleet serve` is up, Metro and Expo process stop with a port check, Gradle caches. Cursor app-support caches dropped. `df -h /` → `df -h ~`. |
| `authoring-a-skill.md` | ADAPT (ported) | Cursor `create-skill` → akit conventions: `skills/<name>/`, frontmatter, the `amillez` list in `manifest.json`, both install loops, README tables, `UPSTREAM.md` for ports, link and `bash -n` validation, one skill change per PR. Closing guidance kept. |
| `orchestrate.md` | ALREADY-HAVE + ADAPT (ported) | Orca owns the DAG (`orchestrate-agents`, ai-eng-practices `big-work-orchestration.md`). The brief template (plus a MODE field naming amillez-mode) and retry-by-failure-mode are adapted into `skills/orchestrate-agents/SKILL.md`; changes listed in `skills/orchestrate-agents/UPSTREAM.md`. Store, `orch`, drain protocol, `gt` stacker, ledger, and cloud spawn rules not ported. |
| `multi-phase-plan.md` | DEFER | 10-lane swarm, `/goal`, `check-plan.mjs` are Cursor-cloud sized. |
| `eval.md` | DROP | Needs arena + Cursor transcripts. |
| `shipping.md` | DROP | Merge only on Agustín's say-so. |
| `autopilot-full.md` | DROP | Owners self-merge; Cursor cloud agents. |
| `autopilot-stack.md` | DROP | Cloud agents + swarm; ideas tracked in steal-from-pstack. |

### Other upstream files

| File | Verdict | Our change |
| --- | --- | --- |
| `principle-*/SKILL.md` (23) | KEEP | Vendored to `principles/<slug>.md` (see Local changes). |
| `pstack/LICENSE` | KEEP | `LICENSE-pstack`, byte-for-byte. |
| `poteto-mode/references/bugbot-triage.md` | ADAPT (ported) | → `references/review-triage.md`. Automated reviewers only; Agustín's comments are always applied. Rubric, pattern format, ask-by-default list, and every learned pattern kept. "Bugbot" → the reviewer, forge → `gh`, `ask` reports for Agustín. |
| `unslop`, `technical-writing`, `tdd` | KEEP | → `references/`, capitalization remap. |
| `poteto-mode/scripts/{watch-pr,orch,check-plan.mjs,bootstrap.ts,package.json,bun.lock}` | DROP | Cursor/Origin/gt/bun tooling. |
| `poteto-mode/scripts/worktree-audit.sh` | ADAPT (ported) | → `scripts/worktree-audit.sh`. Read-only: `--fetch` is opt-in, nothing is deleted, `GIT_OPTIONAL_LOCKS=0` keeps `git status` from rewriting the index. Scans given repos, the current repo, or `--root` (default `$AGENT_WORK_ROOT`, else `~/agent-work`). Transcript column → LAST_TOUCH (newer of index mtime and HEAD commit); buckets `hold-wip`, `hold-open-pr`, `verify-recent`, `safe`, `review`, `prunable`; portable GNU/BSD `stat` and `date`; RUNTIME section (Metro/Expo ports 8081, 8090, 19000, 19001, Expo CLI processes, booted simulators, adb devices). |
| `agents/poteto-agent.md`, `agents/comment-sicko.md` | DROP | Cursor subagent wrappers. |
| `how`, `why`, `architect`, `arena`, `swarm`, `interrogate` | DROP | Not ported. Use `grill-me`, Orca, policy §5. |
| `show-me-your-work/` (`SKILL.md`, `references/decision-log-template.tsv`, `scripts/log.sh`) | ADAPT (ported) | → `references/show-me-your-work.md`, `references/decision-log-template.tsv`, `scripts/decision-log.sh`. Near-verbatim. Frontmatter → H1 plus `**Trigger.**` (upstream description minus the `/show-me-your-work` slash command); `disable-model-invocation` dropped since references are not invoked. Cursor `agent-transcripts/` audit → this run's own Claude Code or Codex session log only. Cross-model review names our lanes (Codex for Claude Code work and the reverse) and reports to Agustín. "Agent conversation" → "agent session", agent id → session id. Skill-name mentions → relative links. "Composing this skill" → "Composing this reference". |
| `blast-radius/SKILL.md` | KEEP (ported) | → `playbooks/blast-radius.md`. Near-verbatim. Frontmatter → `###` playbook title plus an ownership line; `##`/`###` sections → `####` and a bold lead. `how`/`why` companions → the Investigation playbook (`gh pr view`, `gh pr diff`, `git log -S`, `git blame`). "Solid versus React" → render versus effects, JS thread versus native modules. Proof ladder step 5 names Argent or `verify-*`. Step 5 keeps the proof script outside the worktree unless it becomes a regression test. `arena` → the same prompt on a different model lane, plus the size gate to Orca for large work. Skill-name mentions → relative links. Linked from the `SKILL.md` router, `opening-a-pr.md` (`## Blast Radius` section), and `references/review-triage.md` (findings that claim breakage outside the diff). |
| `figure-it-out/SKILL.md` | ADAPT (ported) | → `playbooks/figure-it-out.md`. Near-verbatim. Frontmatter → `###` playbook title plus an ownership line; `##` phases → `####`. Added a "Where it sits" rule: needs parallel workers → Orca, one agent owns the whole loop → Figure it out. The same one-line rule is in the `SKILL.md` size-gate trigger and the `orchestrate-agents` size gate. poteto-mode Principles → `SKILL.md` Principles. `architect`/`arena` → write the target shape plus the same prompt on a different model lane, with `grill-me` for a contested result. "Decide what fans out" → decide what you delegate, with parallel workers sent to the size gate. show-me-your-work → `references/show-me-your-work.md`. Phase E adds Argent or `verify-*`, teardown, and Opening a PR. Principle mentions → relative links. Upstream's `SKILL.md` routing (route here even when a narrower playbook fits) lives in the router entry; Orchestrate is replaced by Orca. |
| `recall/SKILL.md` | FOLDED (into `session-pickup.md`) | Kept: the shared-record sweep (reports, prior fixes, reverts, incidents), its question ("what's the current state, what was tried and didn't hold, what's still reported"), null results as findings, skip-and-say for an unavailable source, and the default-on rule when a target is named. `why` investigators → git history plus `gh` and connected tools. Dropped: Cursor transcript paths and parallel chat-history mining (session-pickup already reads this task's Claude Code or Codex session log), the `automate-me` route, and the separate capsule/threads output contract (the reply gains recurring problems with sources). |
| `typescript-best-practices/` (`SKILL.md`, `references/patterns.md`) | ADAPT (ported, separate skill) | → [`skills/typescript-best-practices/`](../typescript-best-practices/SKILL.md), a separate core skill with its own [`UPSTREAM.md`](../typescript-best-practices/UPSTREAM.md) and `LICENSE-pstack`. Principle mentions → relative cross-skill links into `principles/`. Keeps `paths`, drops `disable-model-invocation`, and the description carries the `.ts`/`.tsx` trigger. Drops the Real tests and Structured telemetry rows. Defers React Native library usage to `react-native-best-practices`. |
| `reflect/` (`SKILL.md`, `references/{judgment,tooling,divergent}-reviewer.md`, `references/synthesizer.md`) | ADAPT (ported) | → [`playbooks/reflect.md`](playbooks/reflect.md) plus `references/reflect-{judgment,tooling,divergent,synthesizer}.md`. A playbook, not a skill, since it is explicit-invoke only and reuses this skill's lanes, session-log paths, and Authoring a skill loop. Frontmatter → `###` title plus ownership line; `disable-model-invocation` dropped, the "reflect" trigger phrases kept in the router entry and the `SKILL.md` description. Cursor `agent-transcripts/` → finished Claude Code or Codex session logs at the Session pickup paths. `Task` fan-out and `pstack-models.mdc` role lines → three parallel headless sessions (Judgment and Divergent on the general-code lane on Claude Code, Tooling on GPT 6 Sol xHigh on Codex) and the synthesizer on Opus 5.5 xHigh, all deferring to the policy. Apply step → one small PR (never merged) or a garden hand-off in the reply; never edits installed skills; Backlog never auto-files. `create-skill` → Authoring a skill; `new skill` rows go to Backlog. Reviewer templates near-verbatim (skill-use scan paths, log wording, routing to source paths); the synthesizer adds a rule routing practice-level findings to ai-eng-practices. |
| `create-verification-skill`, `maintain-verification-skill`, `setup-pstack` | ALREADY-HAVE | `skills/create-verification-skill`, `skills/maintain-verification-skill`, `skills/setup-amillez-models`. |
| cursor-team-kit `deslop`, `control-ui`, `control-cli` | ADAPT | Inline self-review; Argent + `verify-*`. |

## Friday revisit (tracking upstream)

Run during the weekly pstack revisit (see ai-eng-practices `playbooks/steal-from-pstack.md`).

```bash
PIN=ecc249f1e306fc64ddf83c7bed16cacf7c2239db
git clone --filter=blob:none https://github.com/cursor/plugins /tmp/cursor-plugins 2>/dev/null \
  || git -C /tmp/cursor-plugins fetch origin main
cd /tmp/cursor-plugins
git log --oneline "$PIN"..origin/main -- pstack/skills/poteto-mode pstack/skills/principle-\* pstack/LICENSE
git diff --stat "$PIN"..origin/main -- pstack/skills/poteto-mode pstack/skills/principle-\* \
  pstack/skills/unslop pstack/skills/technical-writing pstack/skills/tdd pstack/LICENSE
git show origin/main:pstack/.cursor-plugin/plugin.json | grep '"version"'
```

1. **KEEP files** (principles, LICENSE, KEEP playbooks): re-apply upstream text mechanically, then re-apply the Local changes above.
2. **ADAPT files**: read the upstream diff, port only changes that survive our remaps.
3. **New upstream playbooks/principles**: add a verdict row here before porting.
4. Bump the pinned commit and version in this file in the same PR. Note the revisit date in steal-from-pstack "Last Friday revisit".
5. One small PR per revisit. Skip the PR when nothing relevant changed.
