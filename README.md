# agent-skills

Allowlisted engineering skills for **agent-m1** — **Claude Code + Codex only**.

Playbooks / *when to use* policy live in [`amillez/ai-eng-practices`](https://github.com/amillez/ai-eng-practices). This repo holds **skill bodies** + install/update scripts so we do not hand-duplicate folders on every machine.

**Out of scope:** Cursor plugin / marketplace (`.cursor-plugin`), Cursor My Machines, `register-worker-dir`, `.cursor/skills`, `.cursor/rules`. Grok Bot remains the chat/control plane; coding runs on agent-m1 via Claude Code / Codex.

## Install model (split)

| Pack | Where it lives | How |
| --- | --- | --- |
| **Amillez plugin** (first-party skills + models rules + allowlisted upstream) | **Device / user root** | `./scripts/install.sh` → `~/.claude/skills`, `~/.agents/skills`; rules → `~/.claude/rules/amillez-models.md`, `~/.agents/rules/amillez-models.md`; stamp → `~/.amillez-plugin.json` |
| **Project skills** (e.g. `verify-*`) | **In the repo** | `.claude/skills/…`, `.agents/skills/…` committed with the project |

The amillez plugin must **not** symlink or copy into project trees. No project `.gitignore` block is needed for amillez skills/rules — we do not put them there.

## amillez plugin (Claude Code + Codex)

This repo is the **amillez** skill + rules pack (`amillez-plugin.json`): canonical `skills/` + `templates/models.md` + setup/update scripts. **Goal:** replace hand-copied custom skills. Allowlisted upstream packs still install via `./scripts/install.sh` / the `skills` CLI. Playbooks stay in [`ai-eng-practices`](https://github.com/amillez/ai-eng-practices); **runtime skills live here**.

Coding host is **agent-m1 Claude Code + Codex only**. Cursor plugin / My Machines are out of scope.

### 1. Clone this repo (or pull latest)

```bash
git clone git@github.com:amillez/agent-skills.git ~/agent-work/agent-skills
# or, if already cloned:
cd ~/agent-work/agent-skills && git pull
```

### 2. Global (user-root) install

```bash
cd ~/agent-work/agent-skills
./scripts/install.sh                 # default: core + mobile
# ./scripts/install.sh --groups core           # core only
# ./scripts/install.sh --groups mobile         # core still included + mobile
# ./scripts/install.sh --groups core,mobile    # same as default
```

Installs allowlisted upstream packs + copies first-party from `skills/` into `~/.agents/skills` and `~/.claude/skills`; copies `templates/models.md` to **user** rules dirs; writes `~/.amillez-plugin.json` (and `~/.agents/amillez-plugin.json`). Never `.cursor/`, never project `.claude/` / `.agents/`.

**Groups** (see `manifest.json` `groups` + per-entry `group` tags):

| Group | Always? | Contents |
| --- | --- | --- |
| `core` | **yes** (even with `--groups mobile`) | `amillez-mode`, `grill-me`, `orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models` |
| `mobile` | no | Argent, `animate-expo`, `apple-design`, `review-animations`, `expo-dev-client`, `expo-upgrade`, `react-native-best-practices`, `uniwind`, Codex native vendor set |

Default is **core+mobile**. `--groups core` skips mobile. Future groups (e.g. frontend/backend) will follow the same pattern.

Also install the **Argent CLI** on agent hosts (skills alone are not enough):

```bash
npm install -g @swmansion/argent@0.25.0
argent init -y --no-telemetry --global
```

### 3. **Required** — ensure host install before coding

**Before coding sessions on agent-m1**, ensure the **host** has the amillez plugin (not a project path):

```bash
cd ~/agent-work/agent-skills
./scripts/ensure-install.sh
# thin alias (project path ignored if passed):
# ./scripts/ensure-project.sh
```

Bots/agents do this automatically per [`ai-eng-practices`](https://github.com/amillez/ai-eng-practices) policy (missing pack → install; already present → continue). Optional `--force` refreshes skills + user rules + stamp.

- Detects install via `~/.amillez-plugin.json` (or `~/.agents/amillez-plugin.json`) **or** (legacy) user rules + `setup-amillez-models` under `~/.claude|~/.agents/skills`.
- If missing → runs `update-install.sh` (install + user rules + stamp).
- Prints one line: `amillez plugin: installed` / `already present` / `updated`.

Refresh helpers:

```bash
./scripts/update-install.sh              # refresh user-root skills + rules + stamp
# ./scripts/update-install.sh --groups core
# ./scripts/update-install.sh --skip-upstream   # first-party + vendor + rules only
# deprecated alias (ignores project path): ./scripts/update-project.sh
```

- **`ensure-install.sh`** — **required** entrypoint before coding; idempotent detect → install/refresh at **user root**. Accepts `--groups` (default **core+mobile**).
- **`ensure-project.sh`** — thin wrapper that only calls `ensure-install.sh` (legacy project path ignored).
- **`update-install.sh`** — refresh user skills + copy `templates/models.md` → `~/.claude/rules/amillez-models.md` and `~/.agents/rules/amillez-models.md` + stamp.
- **`install.sh`** — full global install (upstream + first-party + vendor + user rules + stamp).
- **`link-project.sh`** — **OFF by default**. Optional `--project-local` convenience only; not used by ensure. Prefer in-repo project skills instead of linking the plugin into projects.

### Explicit

- Replaces hand-copied custom skills.
- Cursor plugin / My Machines are **out of scope**.
- Coding host is **agent-m1 Claude Code / Codex only**.
- **Project skills** (verify-*, app-specific) stay committed in the project; do not expect ensure to put them there.

## Allowlist

Grouped as **core** / **mobile** in `manifest.json` (and selectable via `--groups` on install/ensure/update). `expo-native-ui` is excluded.

| Skill | Group | Source | When |
| --- | --- | --- | --- |
| All Argent `argent-*` | mobile | `software-mansion/argent` (pinned tag in `manifest.json`) | Skill description |
| `animate-expo` | mobile | `emilkowalski/skills` | Building animations |
| `apple-design` | mobile | `emilkowalski/skills` | Building UIs |
| `review-animations` | mobile | `emilkowalski/skills` | Reviewing / critiquing animation and motion (Emil craft bar). Upstream sets `disable-model-invocation: true` — still allowlisted, but not auto-invoked: launch prompts must name it explicitly for critique passes. |
| `grill-me` | core | `mattpocock/skills` | Stress-test a plan before build |
| `expo-dev-client` | mobile | `expo/skills` | Build and distribute Expo development clients locally or via TestFlight for internal testing. For production TestFlight releases and store submission, use `eas-app-stores`. |
| `expo-upgrade` | mobile | `expo/skills` | Skill description (Expo SDK upgrades, dependency conflicts, deprecated packages, cache cleanup) |
| `react-native-best-practices` | mobile | `software-mansion-labs/skills` | Skill description / when writing, reviewing, or debugging ANY React Native or Expo code |
| `uniwind` | mobile | `uni-stack/uniwind` | Skill description / when building or debugging Uniwind className styling in RN |
| `amillez-mode` | core | **first-party** (pstack `poteto-mode` port, MIT; see `skills/amillez-mode/UPSTREAM.md`) | **Required** working mode for every coding agent (single agent or Orca worker). Launch prompts name it explicitly. |
| `orchestrate-agents` | core | **first-party** (`skills/`) | Fan out large work into parallel isolated prompts (Claude/Codex/mixed) |
| `create-verification-skill` | core | **first-party** (pstack port, amillez overlay) | Generate project-local `verify-<app>` (Launch/Doctor/Drive/Evidence/Cleanup + feature map) |
| `maintain-verification-skill` | core | **first-party** (pstack port, amillez overlay) | Keep a project `verify-<app>` skill + feature map honest |
| `setup-amillez-models` | core | **first-party** (thin setup-pstack replacement) | Policy chooser + install/update **user** Claude/Codex rules templates; never Cursor / `pstack-models.mdc` |
| Codex native set (`api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`) | mobile | **vendor snapshot** (no public skills-lock upstream) | Building native / Nitro modules |

Excluded for now: `autoreview`, Superset pack, Orca orchestration, other design/planning skills, Cursor plugin / worker-dir skills, `expo-native-ui`.

## Model rule template

| Template | Destination (amillez plugin) |
| --- | --- |
| `templates/models.md` | **`~/.claude/rules/amillez-models.md`** and **`~/.agents/rules/amillez-models.md`** (user-level) |

Defaults (2026-09-25): super defined → **GPT 6 Luna Max** (Codex); general code + UI → **Opus 5.5 High** (Claude Code), or **GPT 6 Sol** (xHigh general / High UI, Codex) when Claude Code usage > 70%; Orca coordinator → **Opus 5.5 xHigh**; large reasoning → **Fable 5.1 Medium→High/xhigh**. Workers follow the policy chooser. **Never** writes Cursor rules, `pstack-models.mdc`, or project `.claude/rules/` for the plugin pack. `/setup-amillez-models` and `update-install.sh` / `install.sh` refresh user rules.

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

4. **First-party** (`amillez-mode`, `orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models`) — edit under `skills/`, commit, `git pull` + `./scripts/update-install.sh` (or full `install.sh`). Ensure gate: `./scripts/ensure-install.sh`.

5. **Lockfile** — after installs, `~/.agents/.skill-lock.json` records source URLs/hashes for upstream packs. Prefer that + this repo’s `manifest.json` over ad-hoc copies.

## Layout

```
amillez-plugin.json          # lightweight pack metadata (NOT .cursor-plugin)
skills/                      # canonical first-party skill tree
templates/models.md          # Claude Code / Codex rules (model lanes) → user rules dirs
first-party/README.md        # legacy pointer → skills/
manifest.json                # allowlist + upstream pins (paths → skills/…)
vendor/codex/                # snapshots without public upstream
scripts/install.sh           # user-root Claude/Codex/~/.agents + user rules + stamp
scripts/ensure-install.sh    # REQUIRED before coding: detect → user-root install/refresh + stamp
scripts/ensure-project.sh    # thin alias → ensure-install.sh (project path ignored)
scripts/update-install.sh    # refresh user-root skills + rules + stamp
scripts/update-project.sh    # deprecated alias → update-install.sh
scripts/link-project.sh      # OFF unless --project-local (optional convenience)
scripts/update-upstream.sh
scripts/refresh-codex-vendor.sh
```
