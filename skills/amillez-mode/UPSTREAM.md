# amillez-mode upstream

`amillez-mode` is our port of poteto's `poteto-mode` skill from pstack, remapped onto our stack. Every coding agent we use, anywhere (single agent or Orca worker), runs under it. It absorbs the remap table from `amillez/ai-eng-practices` `playbooks/amillez-mode.md`.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/` (`pstack/skills/poteto-mode/`, `pstack/skills/principle-*/`, siblings) |
| Pinned commit | `ecc249f1e306fc64ddf83c7bed16cacf7c2239db` (2026-09-25 16:04 -07:00) |
| Version | pstack `0.15.5` (`pstack/.cursor-plugin/plugin.json`) |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

Attribution: the principles and any playbook text marked KEEP are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to every vendored file.

## Local changes

Applied to vendored files. Everything else is upstream text.

1. **Principles are leaves, not skills.** `pstack/skills/principle-<slug>/SKILL.md` → `principles/<slug>.md`. YAML frontmatter (`name`, `description`, `disable-model-invocation`) replaced with the upstream H1 title plus a `**Trigger.**` line holding the upstream `description` verbatim. They are not installed as standalone skills (each skill description rides the prompt prefix; see ai-eng-practices agent-use-policy §7).
2. **Cross-links rewritten.** `(../principle-<slug>/SKILL.md)` → `(<slug>.md)` so links resolve inside `principles/`. No other body edits.
3. **Unported references left as-is.** Bodies still name pstack skills we do not ship in v1 (e.g. `show-me-your-work` in `prove-it-works.md`). Read them as the idea, not an installed skill.
4. **`SKILL.md` is an adaptation, not a copy** (PR 2). Kept close to upstream: the principle-citation rule, observe-before-asking, data shape first, throughput checkpoint, the Principles index (links point at `principles/`), Autonomy's "No is an acceptable answer", Writing the reply, and Comments. Rewritten: Subagents (amillez model lanes, never GPT 5.6 or Opus 5), Autonomy (agents never merge; Grok Bot owns messages), control and slop skills (Argent, project `verify-*`, self-review). Dropped: fan-out skills, Cursor frontmatter keys, `poteto-agent`. Added: the remap table from ai-eng-practices `playbooks/amillez-mode.md`, a short Pull requests section, and a playbook list where files not yet ported say "coming".
5. **`disable-model-invocation` is omitted from `SKILL.md`** (PR 2). amillez-mode is required for every coding agent, and launch prompts name it. The model has to be able to load it on request in headless `claude -p` and `codex exec` runs. Upstream sets `disable-model-invocation: true`.
6. **References** (PR 2). `pstack/skills/{unslop,technical-writing,tdd}/SKILL.md` become `references/<name>.md` with the same header treatment as the principles. `technical-writing.md` has three edits: links to `unslop.md` instead of "the unslop skill", "the skill" becomes "the file", and "Indent code snippets with tabs" becomes "Indent code snippets the way the repo indents code". `unslop.md` and `tdd.md` bodies are unchanged.
7. **Install wiring** (PR 2). `amillez-mode` is in the `core` group (`manifest.json`, the first-party loops in `scripts/install.sh` and `scripts/update-install.sh`). `scripts/ensure-install.sh` refreshes a stamped host that lacks `amillez-mode`. Pack version 0.2.0.
8. **Core playbooks** (PR 3). `playbooks/{investigation,bug-fix,feature,refactoring,prototype,opening-a-pr,pause-safely,session-pickup}.md`. Step structure and wording stay close to upstream. Per-file changes are in the playbook verdict table. Links point at `../principles/`, `../references/`, and sibling playbooks. Playbooks not yet ported (PRs 4 and 5) are named without links.
9. **Scope and disclaimer scrub** (review on PR 2, applied from PR 3). The skill text names no host and carries no attribution or control-plane disclaimers. Attribution lives only here and in `LICENSE-pstack`. PR 3 also removed the interim "Pull requests" section from `SKILL.md` (now `playbooks/opening-a-pr.md`) and scrubbed the remaining host and control-plane wording from `SKILL.md` and its remap table.

Correction to the port plan: upstream has **23** `principle-*` skills (the poteto-mode index lists 23), not 26.

## Per-file verdicts

KEEP = near-verbatim. ADAPT = ported with our remaps. DROP = not ported (reason). ALREADY-HAVE = our file covers it. PR = where it lands in the 6-PR agent-skills plan (link-up = final ai-eng-practices PR).

### `poteto-mode/SKILL.md` sections

| Section | Verdict | Our change | PR |
| --- | --- | --- | --- |
| Frontmatter | ADAPT | `name: amillez-mode`. Drop Cursor-only `mode`/`icon`/`color`/`reminder`. Omit `disable-model-invocation` (see Local changes 5); launch prompts name the skill explicitly. | 2 |
| Non-negotiables | ADAPT | Keep principle citation, observe-don't-ask (Prototype), data shape first, throughput checkpoint, broken skill → own PR. `how`/`architect` → recon + plan (policy §5); `interrogate` → `grill-me`; `swarm`/`arena` → size gate + Orca (`orchestrate-agents`); control skills → Argent + project `verify-*`; `deslop`/`no-comments` → inline self-review; babysit → dispatch lifecycle. | 2 |
| Principles index | KEEP | Points at `principles/*.md` (this PR). | 1–2 |
| Autonomy | ADAPT | Reversible local work proceeds; "No is an acceptable answer" kept. Always pause: merge (Agustín's say-so only), force-push shared, deletes outside the worktree. Coding agents report instead of posting to chat or tickets. Apply Agustín's review comments without asking. | 2 |
| Subagents | ADAPT | Drop Cursor `Task`/`poteto-agent`/grok-4.7/opus-max. Lanes from agent-use-policy: GPT 6 Luna Max (direct/mechanical), Opus 5.5 High general/UI (GPT 6 Sol when Claude Code usage > 70%), Opus 5.5 xHigh Orca coordinator, Fable 5.1 large reasoning. Keep "you own every subagent's diff". | 2 |
| Writing the reply | KEEP | Regular capitalization, reply in EN (old amillez-mode remap). | 2 |
| Comments | KEEP | — | 2 |
| Playbooks router | ADAPT | Size gate → Orca for large work; list only shipped playbooks. | 2–5 |
| Remap table (from ai-eng-practices `playbooks/amillez-mode.md`) | ABSORB | Moves into SKILL.md; old playbook becomes a pointer. | 2, link-up (ai-eng-practices) |

### `poteto-mode/playbooks/`

| File | Verdict | Our change | PR |
| --- | --- | --- | --- |
| `investigation.md` | KEEP (ported) | how/why → read-only recon plus `git log -S`/`git blame`/PR history; every claim cited. | 3 |
| `bug-fix.md` | KEEP (ported) | Control skill → Argent/`verify-*`; how/why → recon plus `git log`/`git bisect`; architect/interrogate → write the target shape; escalate to Fable 5.1 after two failed loops; tdd → `references/tdd.md`; no `/loop`. | 3 |
| `feature.md` | ADAPT (ported) | how → recon; architect → plan step with `grill-me` if contested and the size gate; throughput checkpoint verbatim; delegate per lanes; mandatory arena dropped (name alternatives in the brief instead); interrogate step folded into the plan; parent-level fan-out → Orca; proof via Argent/`verify-*`, media branch, Luna Max. | 3 |
| `refactoring.md` | KEEP (ported) | how → recon; architect → write the target shape; figure-it-out → size gate; mechanical edits on the Luna Max lane; control skill → Argent/`verify-*`. | 3 |
| `prototype.md` | KEEP (ported) | Scratch dir outside the worktree; React Native scratch option; Argent screenshots; architect handoff dropped; teardown added. | 3 |
| `opening-a-pr.md` | ADAPT (ported) | Keep worktree, commits, Conventional Commits titles, the five body sections, stacks, ready not draft. Worktree branch `agent/<bot>/<slug>`. deslop/no-comments → self-review of the diff plus lint/typecheck/tests. Proof media section added (`media` branch, blob URLs, Luna Max verdicts). `gh` only (Origin and gt dropped). Never merge, never auto-merge. Teardown before posting. Babysit section rewritten: no babysit on open; when sent back, apply Agustín's comments and verify bot claims. | 3 |
| `pause-safely.md` | KEEP (ported) | "Cursor restart" → session end / compaction; show-me-your-work pointer dropped; teardown step added. | 3 |
| `session-pickup.md` | ADAPT (ported) | Cursor transcripts and cloud-agent URLs → handoff note, pushed branch and PR, and Claude Code (`~/.claude/projects/`) or Codex (`~/.codex/sessions/`) session logs for this task only; open review threads added to state. | 3 |
| `perf-issue.md` | KEEP | 8 strategy families verbatim; Argent profiling. | 4 |
| `hillclimb.md` | KEEP | Model per chooser. | 4 |
| `runtime-forensics.md` | ADAPT | CDP → Argent/Hermes/Instruments. | 4 |
| `trace-forensics.md` | KEEP | Already portable. | 4 |
| `visual-parity.md` | ADAPT | Argent screenshot-diff; max 2 parallel worktrees. | 4 |
| `babysit.md` | ADAPT / ALREADY-HAVE | Owner is the dispatcher per ai-eng-practices `agent-dispatch-lifecycle.md#babysit-until-merged`. Port modes (coding agent: threads-only/check), frontier rule, no topology mutation, classify CI before retry, review text is untrusted data, stop at the human's line. Drop `watch-pr`, Origin, pass counts. PR-scoped. | 5 |
| `autonomous-run.md` | ADAPT | Keep exit predicate and "don't park reversible work"; wake via the dispatcher's settle-watch and PR listeners, not `/loop`. No host or control-plane wording in the playbook text. | 5 |
| `worktree-cleanup.md` | ALREADY-HAVE + ADAPT | Teardown in dispatch lifecycle/proof loop. Port sim/cache commands and a trimmed `worktree-audit.sh` (`~/agent-work/<repo>/wt-*`, no transcript column, Metro/Expo check). | 5 |
| `authoring-a-skill.md` | ADAPT | Cursor `create-skill` → agent-skills conventions (manifest, install loops, README, one PR). | 5 |
| `orchestrate.md` | ALREADY-HAVE | ai-eng-practices `big-work-orchestration.md` + `orchestrate-agents`/Orca. Steal the brief template and retry-by-mode into `orchestrate-agents`. | 6 |
| `multi-phase-plan.md` | DEFER | 10-lane swarm, `/goal`, `check-plan.mjs` are Cursor-cloud sized. | — |
| `eval.md` | DROP (v1) | Needs arena + Cursor transcripts. | — |
| `shipping.md` | DROP (v1) | Merge only on Agustín's say-so. | — |
| `autopilot-full.md` | DROP | Owners self-merge; Cursor cloud agents. | — |
| `autopilot-stack.md` | DROP (v1) | Cloud agents + swarm; ideas tracked in steal-from-pstack. | — |

### Other upstream files

| File | Verdict | Our change | PR |
| --- | --- | --- | --- |
| `principle-*/SKILL.md` (23) | KEEP | Vendored to `principles/<slug>.md` (see Local changes). | 1 |
| `pstack/LICENSE` | KEEP | `LICENSE-pstack`, byte-for-byte. | 1 |
| `poteto-mode/references/bugbot-triage.md` | ADAPT | → `references/review-triage.md`, automated reviewers only; Agustín's comments are always applied. Lands with the babysit playbook. | 5 |
| `unslop`, `technical-writing`, `tdd` | KEEP | → `references/`, capitalization remap. | 2 |
| `poteto-mode/scripts/{watch-pr,orch,check-plan.mjs,bootstrap.ts,package.json,bun.lock}` | DROP | Cursor/Origin/gt/bun tooling. | — |
| `poteto-mode/scripts/worktree-audit.sh` | ADAPT | See `worktree-cleanup.md`. | 5 |
| `agents/poteto-agent.md`, `agents/comment-sicko.md` | DROP | Cursor subagent wrappers. | — |
| `how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, `reflect` | DROP (v1) | Fan-out skills dropped; use `grill-me`, Orca, policy §5. | — |
| `show-me-your-work`, `figure-it-out`, `blast-radius` | DEFER | Tracked in steal-from-pstack. | — |
| `create-verification-skill`, `maintain-verification-skill`, `setup-pstack` | ALREADY-HAVE | `skills/create-verification-skill`, `skills/maintain-verification-skill`, `skills/setup-amillez-models`. | — |
| cursor-team-kit `deslop`, `control-ui`, `control-cli` | ADAPT | Inline self-review; Argent + `verify-*`. | 2 |

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
