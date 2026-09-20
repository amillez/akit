# agent-skills

Allowlisted engineering skills for **agent-m1** — **Claude Code + Codex only**.

Playbooks / *when to use* policy live in [`amillez/ai-eng-practices`](https://github.com/amillez/ai-eng-practices). This repo holds **skill bodies** + install/update scripts so we do not hand-duplicate folders on every machine.

**Out of scope:** Cursor plugin / marketplace (`.cursor-plugin`), Cursor My Machines, `register-worker-dir`, `.cursor/skills`, `.cursor/rules`. Grok Bot remains the chat/control plane; coding runs on agent-m1 via Claude Code / Codex.

## Device vs Project

| | **Device (host)** | **Project (in-repo)** |
| --- | --- | --- |
| **Where** | `~/.claude/skills`, `~/.agents/skills` + user rules + stamp | `<repo>/.claude/skills/<name>`, `<repo>/.agents/skills/<name>` (**committed**, shared by teammates) |
| **What** | **Core only** by default | Curated mobile/native skills **only when the project needs them** |
| **How** | `./scripts/install.sh` / `ensure-install.sh` / `update-install.sh` | `./scripts/add-project-skills.sh <project> --skills a,b,c` (copies real files) |
| **Not** | No `~/.codex` (Codex uses `~/.agents`). No dumping the whole mobile set on the host. | Do **not** install unused skills (no vision-camera skill if the app does not use that lib) |

Optional device group **`argent`** (UI drive on agent-m1): `./scripts/install.sh --groups core,argent`. Argent stays **device/host** — not a project skill. Also install the Argent CLI separately (skills alone are not enough).

The amillez **core** plugin must **not** symlink/copy into project trees. Project skills are explicit copies you commit.

## Device — core plugin (Claude Code + Codex)

### 1. Clone this repo (or pull latest)

```bash
git clone git@github.com:amillez/agent-skills.git ~/agent-work/agent-skills
# or, if already cloned:
cd ~/agent-work/agent-skills && git pull
```

### 2. Global (user-root) install — **core only**

```bash
cd ~/agent-work/agent-skills
./scripts/install.sh                 # default: core only
# ./scripts/install.sh --groups core
# ./scripts/install.sh --groups core,argent   # optional Argent on device
```

Installs core upstream (`grill-me`) + copies first-party from `skills/` into `~/.agents/skills` and `~/.claude/skills`; copies `templates/models.md` to **user** rules dirs; writes `~/.amillez-plugin.json` (and `~/.agents/amillez-plugin.json`). Never `.cursor/`, never `~/.codex/`, never project `.claude/` / `.agents/`.

**Device groups** (see `manifest.json`):

| Group | Default? | Contents |
| --- | --- | --- |
| `core` | **yes** | `grill-me`, `orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models` + rules + stamp |
| `argent` | no | All Argent `argent-*` skills (UI drive tooling). Pass `--groups core,argent`. |

Legacy `--groups mobile` on device install is **rejected** — those skills are project-scoped (below).

Optional Argent CLI on agent hosts:

```bash
npm install -g @swmansion/argent@0.25.0
argent init -y --no-telemetry --global
```

### 3. **Required** — ensure host install before coding

```bash
cd ~/agent-work/agent-skills
./scripts/ensure-install.sh          # default: core only
# thin alias (project path ignored if passed):
# ./scripts/ensure-project.sh
```

Bots/agents do this automatically per [`ai-eng-practices`](https://github.com/amillez/ai-eng-practices) policy (missing pack → install **core**; already present → continue). Optional `--force` refreshes. Optional `--groups core,argent` when Argent is needed on the host.

- Detects install via `~/.amillez-plugin.json` (or `~/.agents/amillez-plugin.json`) **or** (legacy) user rules + `setup-amillez-models` under `~/.claude|~/.agents/skills`.
- If missing → runs `update-install.sh` (install + user rules + stamp).
- Prints one line: `amillez plugin: installed` / `already present` / `updated`.

Refresh:

```bash
./scripts/update-install.sh              # refresh user-root **core** + rules + stamp
# ./scripts/update-install.sh --groups core,argent
# ./scripts/update-install.sh --skip-upstream
# deprecated alias (ignores project path): ./scripts/update-project.sh
```

## Project — curated mobile / native skills

Install **only when the project needs them**. Copies land in **both** `.claude/skills` and `.agents/skills`, as real files ready to **commit** (teammates do not need your personal checkout).

```bash
# Suggest from package.json deps:
./scripts/suggest-project-skills.sh /path/to/app

# Copy selected skills (idempotent; refuses clobber without --force):
./scripts/add-project-skills.sh /path/to/app --skills expo-dev-client,expo-upgrade,react-native-best-practices

# List catalog:
./scripts/add-project-skills.sh --list

# Thin wrapper (same as add-project-skills):
./scripts/link-project.sh /path/to/app --skills uniwind
```

**Project catalog** (do not dump unused):

| Skill | Typical trigger |
| --- | --- |
| `animate-expo`, `apple-design`, `review-animations` | animations / Apple-like UI / motion review |
| `expo-dev-client`, `expo-upgrade` | Expo apps |
| `react-native-best-practices` | any RN / Expo code |
| `uniwind` | Uniwind className styling |
| `api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift` | Nitro / native modules |
| `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera` | those libraries |

Sources: `vendor/codex/*` for Codex native snapshots; upstream packs fetched into `.cache/upstream-skills/` (or copied from an existing device install) so the project gets **real files**, not symlinks.

**Argent** is **not** in this list — keep it device/host via `--groups core,argent`.

## Scripts cheat sheet

| Script | Role |
| --- | --- |
| `ensure-install.sh` | **Required** before coding — host **core** detect → install/refresh |
| `ensure-project.sh` | Thin alias → `ensure-install.sh` (legacy project path ignored) |
| `install.sh` | Device install (default **core**; optional `argent`) |
| `update-install.sh` | Refresh device skills + user rules + stamp |
| `update-project.sh` | Deprecated alias → `update-install.sh` |
| `add-project-skills.sh` | Copy curated skills into a project (commit them) |
| `suggest-project-skills.sh` | Suggest skills from `package.json` deps |
| `link-project.sh` | Thin wrapper → `add-project-skills.sh` (no `--project-local`) |
| `update-upstream.sh` | `npx skills update -g` tip helper |
| `refresh-codex-vendor.sh` | Refresh `vendor/codex` snapshots from device |

## Allowlist

| Skill | Target | Source | When |
| --- | --- | --- | --- |
| All Argent `argent-*` | **device** (`argent` group) | `software-mansion/argent` (pinned in `manifest.json`) | UI drive on agent-m1 |
| `grill-me` | **device** (`core`) | `mattpocock/skills` | Stress-test a plan before build |
| `orchestrate-agents` | **device** (`core`) | first-party `skills/` | Fan out large work |
| `create-verification-skill` | **device** (`core`) | first-party | Generate project-local `verify-<app>` |
| `maintain-verification-skill` | **device** (`core`) | first-party | Keep `verify-<app>` honest |
| `setup-amillez-models` | **device** (`core`) | first-party | User rules templates (never Cursor / `pstack-models.mdc`) |
| `animate-expo`, `apple-design`, `review-animations` | **project** | `emilkowalski/skills` | Animations / UI / motion review |
| `expo-dev-client`, `expo-upgrade` | **project** | `expo/skills` | Expo clients / upgrades |
| `react-native-best-practices` | **project** | `software-mansion-labs/skills` | RN / Expo coding |
| `uniwind` | **project** | `uni-stack/uniwind` | Uniwind styling |
| Codex native set (`api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`) | **project** | `vendor/codex` | Native / Nitro |

Excluded for now: `autoreview`, Superset pack, Orca orchestration, other design/planning skills, Cursor plugin / worker-dir skills, `expo-native-ui`.

## Model rule template

| Template | Destination (amillez plugin) |
| --- | --- |
| `templates/models.md` | **`~/.claude/rules/amillez-models.md`** and **`~/.agents/rules/amillez-models.md`** (user-level) |

Defaults: Claude **Opus High** for bot-dispatched Claude sessions; workers follow the policy chooser. **Never** writes Cursor rules, `pstack-models.mdc`, `~/.codex/`, or project `.claude/rules/` for the plugin pack.

## Keeping skills up to date

1. **Device core refresh:** `./scripts/update-install.sh` (or `ensure-install.sh --force`).
2. **Upstream device packs** (grill-me; Argent when enabled): `npx skills update -g -y` or `./scripts/update-upstream.sh`.
3. **Argent version bumps** — pin CLI + `manifest.json` `upstream[argent].ref`, then `./scripts/install.sh --groups core,argent`.
4. **Codex vendor** — `./scripts/refresh-codex-vendor.sh` on a machine with current Codex skills, commit `vendor/codex`, then re-run `add-project-skills.sh … --force` in projects that use those skills.
5. **Project skill bumps** — re-run `add-project-skills.sh <project> --skills … --force` and commit.

## Layout

```
amillez-plugin.json          # lightweight pack metadata (NOT .cursor-plugin)
skills/                      # canonical first-party skill tree (device core)
templates/models.md          # → user rules dirs
manifest.json                # allowlist: device core/argent + project catalog
vendor/codex/                # Codex native snapshots (project-scoped copies)
.cache/upstream-skills/      # local fetch cache for project copies (gitignored)
scripts/install.sh           # device: default core; optional argent
scripts/ensure-install.sh    # REQUIRED before coding: host core ensure
scripts/ensure-project.sh    # thin alias → ensure-install.sh
scripts/update-install.sh    # refresh device core + rules + stamp
scripts/add-project-skills.sh
scripts/suggest-project-skills.sh
scripts/link-project.sh      # thin wrapper → add-project-skills
scripts/update-upstream.sh
scripts/refresh-codex-vendor.sh
```
