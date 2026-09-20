# agent-skills

Allowlisted engineering skills for **agent-m1** — **Claude Code + Codex only**.

Playbooks / *when to use* policy live in [`amillez/ai-eng-practices`](https://github.com/amillez/ai-eng-practices). This repo holds **skill bodies** + install/update scripts so we do not hand-duplicate folders on every machine.

**Out of scope:** Cursor plugin / marketplace (`.cursor-plugin`), Cursor My Machines, `register-worker-dir`, `.cursor/skills`, `.cursor/rules`. Grok Bot remains the chat/control plane; coding runs on agent-m1 via Claude Code / Codex.

## Install model (Device vs Project)

| | **Device (host)** — primary | **Project (in-repo)** — optional mirror |
| --- | --- | --- |
| **Where** | `~/.claude/skills`, `~/.agents/skills` + user rules + stamp (**no `~/.codex`** — Codex uses `~/.agents`) | `<repo>/.claude/skills/<name>`, `<repo>/.agents/skills/<name>` (**committed**, shared by teammates) |
| **What** | Default **core+mobile** (Argent, Emil, Expo, RN best practices, Uniwind, Codex Nitro vendor set, …) | Selected **stack-relevant** skills only when useful for teammates — e.g. a Uniwind app preferably also has `uniwind` in-repo. **Not** a dump of the whole mobile set into every project. |
| **How** | `./scripts/install.sh` / `ensure-install.sh` / `update-install.sh` (default groups `core,mobile`) | Optional: `./scripts/add-project-skills.sh <project> --skills uniwind` (copies real files, ready to commit) |
| **Also in-repo** | — | Project-local skills such as `verify-*` stay committed as today |

The amillez plugin’s **primary home is the device**. Ensure does **not** install into project trees. Optionally mirroring a few stack skills into a project is for teammates who share the repo — those skills still exist on device.

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

Installs allowlisted upstream packs + copies first-party from `skills/` into `~/.agents/skills` and `~/.claude/skills`; copies `templates/models.md` to **user** rules dirs; writes `~/.amillez-plugin.json` (and `~/.agents/amillez-plugin.json`). Never `.cursor/`, never `~/.codex/` (Codex uses `~/.agents`), never project `.claude/` / `.agents/` for the device pack.

**Groups** (see `manifest.json` `groups` + per-entry `group` tags):

| Group | Always? | Contents |
| --- | --- | --- |
| `core` | **yes** (even with `--groups mobile`) | `grill-me`, `orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models` |
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
- **`link-project.sh`** — **OFF by default**. Optional `--project-local` convenience only; not used by ensure.
- **`add-project-skills.sh`** — **optional** teammate mirror: copy selected mobile/stack skills into a project’s `.claude/skills` + `.agents/skills` (commit them). Device remains the primary home (`core+mobile`).

### Optional — mirror selected skills into a project

When a repo’s stack makes a skill useful for **every teammate** (even though it already lives on the device), copy just those names and commit:

```bash
./scripts/add-project-skills.sh --list
./scripts/add-project-skills.sh /path/to/app --skills uniwind
# ./scripts/add-project-skills.sh /path/to/app --skills expo-dev-client,react-native-best-practices
```

Do **not** require dumping the whole mobile set into every project. Argent stays device/host (part of mobile install); it is not a project mirror target.

### Explicit

- Replaces hand-copied custom skills.
- Cursor plugin / My Machines are **out of scope**.
- Coding host is **agent-m1 Claude Code / Codex only**.
- **Device default** remains **core+mobile** at `~/.claude` / `~/.agents` (no `~/.codex`).
- **Project** = optional mirror of stack-relevant skills for teammates + committed `verify-*`; ensure does not put the plugin pack there.

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

Defaults: Claude **Opus High** for bot-dispatched Claude sessions; workers follow the policy chooser. **Never** writes Cursor rules, `pstack-models.mdc`, or project `.claude/rules/` for the plugin pack. `/setup-amillez-models` and `update-install.sh` / `install.sh` refresh user rules.

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

4. **First-party** (`orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models`) — edit under `skills/`, commit, `git pull` + `./scripts/update-install.sh` (or full `install.sh`). Ensure gate: `./scripts/ensure-install.sh`.

5. **Lockfile** — after installs, `~/.agents/.skill-lock.json` records source URLs/hashes for upstream packs. Prefer that + this repo’s `manifest.json` over ad-hoc copies.

## Layout

```
amillez-plugin.json          # lightweight pack metadata (NOT .cursor-plugin)
skills/                      # canonical first-party skill tree
templates/models.md          # Claude Code / Codex rules (Opus High defaults) → user rules dirs
first-party/README.md        # legacy pointer → skills/
manifest.json                # allowlist + upstream pins (paths → skills/…)
vendor/codex/                # snapshots without public upstream
scripts/install.sh           # user-root Claude/Codex/~/.agents + user rules + stamp
scripts/ensure-install.sh    # REQUIRED before coding: detect → user-root install/refresh + stamp
scripts/ensure-project.sh    # thin alias → ensure-install.sh (project path ignored)
scripts/update-install.sh    # refresh user-root skills + rules + stamp
scripts/update-project.sh    # deprecated alias → update-install.sh
scripts/link-project.sh      # OFF unless --project-local (optional convenience)
scripts/add-project-skills.sh # optional: mirror selected skills into a project (commit)
scripts/update-upstream.sh
scripts/refresh-codex-vendor.sh
```
