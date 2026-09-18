# agent-skills

Allowlisted engineering skills for **agent-m1** (Claude Code + Codex), Cursor (plugin + project links), and the daily driver.

Playbooks / *when to use* policy live in [`amillez/ai-eng-practices`](https://github.com/amillez/ai-eng-practices). This repo holds **skill bodies** + install/update scripts so we do not hand-duplicate folders on every machine.

## Allowlist

| Skill | Source | When |
| --- | --- | --- |
| All Argent `argent-*` | `software-mansion/argent` (pinned tag in `manifest.json`) | Skill description |
| `animate-expo` | `emilkowalski/skills` | Building animations |
| `apple-design` | `emilkowalski/skills` | Building UIs |
| `review-animations` | `emilkowalski/skills` | Reviewing / critiquing animation and motion (Emil craft bar). Upstream sets `disable-model-invocation: true` — still allowlisted, but not auto-invoked: launch prompts must name it explicitly for critique passes. |
| `grill-me` | `mattpocock/skills` | Stress-test a plan before build |
| `expo-native-ui` | `expo/skills` | Building native UI |
| `expo-dev-client` | `expo/skills` | Build and distribute Expo development clients locally or via TestFlight for internal testing. For production TestFlight releases and store submission, use `eas-app-stores`. |
| `expo-upgrade` | `expo/skills` | Skill description (Expo SDK upgrades, dependency conflicts, deprecated packages, cache cleanup) |
| `react-native-best-practices` | `software-mansion-labs/skills` | Skill description / when writing, reviewing, or debugging ANY React Native or Expo code |
| `uniwind` | `uni-stack/uniwind` | Skill description / when building or debugging Uniwind className styling in RN |
| `orchestrate-agents` | **first-party** (`skills/`) | Fan out large work into parallel isolated prompts (Claude/Codex/mixed) |
| `create-verification-skill` | **first-party** (pstack port, amillez overlay) | Generate project-local `verify-<app>` (Launch/Doctor/Drive/Evidence/Cleanup + feature map) |
| `maintain-verification-skill` | **first-party** (pstack port, amillez overlay) | Keep a project `verify-<app>` skill + feature map honest |
| `setup-amillez-models` | **first-party** (thin setup-pstack replacement) | Policy chooser + optional `models.mdc` / rules templates; do not write `pstack-models.mdc` |
| `register-worker-dir` | **first-party** | Register `~/agent-work/<repo>` on agent-m1 LaunchAgent `--worker-dir` for Cursor My Machines `worker=agent-m1` |
| Codex native set (`api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`) | **vendor snapshot** (no public skills-lock upstream) | Building native / Nitro modules |

Excluded for now: `autoreview`, Superset pack, Orca orchestration, other design/planning skills.

## Cursor plugin (step 1)

This repo is also packaged as a **Cursor-style plugin** (pstack-shaped: `.cursor-plugin/plugin.json` + canonical `skills/`). **Goal:** replace scattering custom skills by hand. Allowlisted upstream packs still install via `./scripts/install.sh` / the `skills` CLI. Playbooks stay in [`ai-eng-practices`](https://github.com/amillez/ai-eng-practices); **runtime skills live here**.

Marketplace publish is **not** required yet (private / path install is enough for step 1). Do not vendor all of pstack.

### Local / dev install (Cursor)

```bash
git clone git@github.com:amillez/agent-skills.git ~/agent-work/agent-skills
```

In Cursor, add the plugin **from path** pointing at the clone (Add Plugin → from folder / local path — whatever your Cursor build exposes for private plugins). The plugin reads `.cursor-plugin/plugin.json` and loads `./skills/`.

### Per-project skill symlinks (Claude / Codex / Cursor folders)

For harnesses that look at project-local skill dirs (and for Claude/Codex alongside the Cursor plugin):

```bash
cd ~/agent-work/agent-skills
./scripts/link-project.sh /path/to/project
```

This creates idempotent per-skill symlinks:

- `.cursor/skills/<name>` → `<agent-skills>/skills/<name>`
- `.claude/skills/<name>` → same
- `.agents/skills/<name>` → same

By default the script links to **this checkout**. Override with `--skills-root`, or it falls back to `~/agent-work/agent-skills` when needed. Pass `--force` to replace a real directory or a symlink that points elsewhere (it will not clobber without `--force`).

### Model rule templates

Lightweight bot/orchestrator defaults (not a full setup-pstack role map):

| Template | Typical destination |
| --- | --- |
| `templates/models.cursor.mdc` | `.cursor/rules/amillez-models.mdc` (or `~/.cursor/rules/`) |
| `templates/models.claude.md` | `.claude/rules/amillez-models.md` and/or `.agents/rules/amillez-models.md` |

`/setup-amillez-models` offers installing these. Defaults: Cursor **Grok 4.6 High**, Claude **Opus 5 High**; workers follow the policy chooser; Fast off; agent-m1 for sim prove. **Never** writes `pstack-models.mdc`.

## Install on a machine (global Claude / Codex)

```bash
git clone git@github.com:amillez/agent-skills.git ~/agent-work/agent-skills
cd ~/agent-work/agent-skills
./scripts/install.sh
```

`install.sh` still installs allowlisted upstream packs + copies **first-party from `skills/`** (canonical) into `~/.agents/skills`, `~/.claude/skills`, and `~/.codex/skills`. Existing global install flow is preserved.

Also install the **Argent CLI** on agent hosts (skills alone are not enough):

```bash
npm install -g @swmansion/argent@0.25.0
argent init -y --no-telemetry --global
```

## Keeping skills up to date

Upstream packs (Argent, Emil, Matt, Expo, Software Mansion Labs, Uniwind) are managed by the [`skills`](https://www.npmjs.com/package/skills) CLI — same tool as `npx skills add`.

1. **Routine refresh** (pulls latest for globally installed skills that the CLI tracks):

   ```bash
   npx skills update -g -y
   ```

   Or: `./scripts/update-upstream.sh`

2. **Argent version bumps** — pin CLI and skills tag together. Update `manifest.json` `upstream[argent].ref`, upgrade `@swmansion/argent`, then re-run the Argent `skills add …#<ref>` line from `install.sh`.

3. **Codex native vendor** — those skills are not in a public skills package we lock. Refresh from a machine that has current Codex skills:

   ```bash
   ./scripts/refresh-codex-vendor.sh
   git commit -am "chore: refresh Codex native skill snapshots"
   ```

   Then on other machines: `git pull && ./scripts/install.sh` (vendor copy step).

4. **First-party** (`orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models`, `register-worker-dir`) — edit under `skills/`, commit, `git pull` + re-run the first-party copy section of `install.sh` (or full install). For project links, re-run `./scripts/link-project.sh` only if skills were added/renamed.

5. **Lockfile** — after installs, `~/.agents/.skill-lock.json` records source URLs/hashes for upstream packs. Prefer that + this repo’s `manifest.json` over ad-hoc copies.

## Layout

```
.cursor-plugin/plugin.json   # Cursor plugin manifest (name: amillez)
skills/                      # canonical first-party skill tree (plugin + install source)
templates/                   # models.cursor.mdc / models.claude.md
first-party/                 # legacy pointer only — do not add new skill bodies here
manifest.json                # allowlist + upstream pins
vendor/codex/                # snapshots without public upstream
scripts/install.sh           # global Claude/Codex/agents install (copies from skills/)
scripts/link-project.sh      # per-project skill symlinks
scripts/update-upstream.sh
scripts/refresh-codex-vendor.sh
```
