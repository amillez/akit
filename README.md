# agent-skills

Allowlisted engineering skills for **agent-m1** — **Claude Code + Codex only**.

Playbooks / *when to use* policy live in [`amillez/ai-eng-practices`](https://github.com/amillez/ai-eng-practices). This repo holds **skill bodies** + install/update scripts so we do not hand-duplicate folders on every machine.

**Out of scope:** Cursor plugin / marketplace (`.cursor-plugin`), Cursor My Machines, `register-worker-dir`, `.cursor/skills`, `.cursor/rules`. Grok Bot remains the chat/control plane; coding runs on agent-m1 via Claude Code / Codex.

## amillez plugin (Claude Code + Codex)

This repo is the **amillez** skill + rules pack (`amillez-plugin.json`): canonical `skills/` + `templates/models.claude.md` + setup/update scripts. **Goal:** replace hand-copied custom skills. Allowlisted upstream packs still install via `./scripts/install.sh` / the `skills` CLI. Playbooks stay in [`ai-eng-practices`](https://github.com/amillez/ai-eng-practices); **runtime skills live here**.

Coding host is **agent-m1 Claude Code + Codex only**. Cursor plugin / My Machines are out of scope.

### 1. Clone this repo (or pull latest)

```bash
git clone git@github.com:amillez/agent-skills.git ~/agent-work/agent-skills
# or, if already cloned:
cd ~/agent-work/agent-skills && git pull
```

### 2. Global install

```bash
cd ~/agent-work/agent-skills
./scripts/install.sh
```

Installs allowlisted upstream packs + copies first-party from `skills/` into `~/.agents/skills`, `~/.claude/skills`, and `~/.codex/skills` (never `.cursor/`).

Also install the **Argent CLI** on agent hosts (skills alone are not enough):

```bash
npm install -g @swmansion/argent@0.25.0
argent init -y --no-telemetry --global
```

### 3. Per project: link, then update

```bash
cd ~/agent-work/agent-skills
./scripts/link-project.sh /path/to/project
./scripts/update-project.sh /path/to/project
```

Or just:

```bash
./scripts/update-project.sh /path/to/project   # re-links skills + refreshes rules
```

- **`link-project.sh`** — idempotent per-skill symlinks into `.claude/skills/<name>` and `.agents/skills/<name>` only (**never** `.cursor/skills`).
- **`update-project.sh`** — re-runs link + copies/updates `templates/models.claude.md` → `.claude/rules/amillez-models.md` and `.agents/rules/amillez-models.md` (idempotent; never `.cursor/rules`).

### Explicit

- Replaces hand-copied custom skills.
- Cursor plugin / My Machines are **out of scope**.
- Coding host is **agent-m1 Claude Code / Codex only**.

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
| `setup-amillez-models` | **first-party** (thin setup-pstack replacement) | Policy chooser + install/update Claude/Codex rules templates; never Cursor / `pstack-models.mdc` |
| Codex native set (`api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`) | **vendor snapshot** (no public skills-lock upstream) | Building native / Nitro modules |

Excluded for now: `autoreview`, Superset pack, Orca orchestration, other design/planning skills, Cursor plugin / worker-dir skills.

## Model rule template

| Template | Typical destination |
| --- | --- |
| `templates/models.claude.md` | `.claude/rules/amillez-models.md` and/or `.agents/rules/amillez-models.md` (optional `~/.claude/rules/`) |

Defaults: Claude **Opus High** for bot-dispatched Claude sessions; workers follow the policy chooser. **Never** writes Cursor rules or `pstack-models.mdc`. `/setup-amillez-models` offers installing these; `update-project.sh` refreshes them.

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

4. **First-party** (`orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models`) — edit under `skills/`, commit, `git pull` + re-run the first-party copy section of `install.sh` (or full install). For project links/rules: `./scripts/update-project.sh /path/to/project`.

5. **Lockfile** — after installs, `~/.agents/.skill-lock.json` records source URLs/hashes for upstream packs. Prefer that + this repo’s `manifest.json` over ad-hoc copies.

## Layout

```
amillez-plugin.json          # lightweight pack metadata (NOT .cursor-plugin)
skills/                      # canonical first-party skill tree
templates/models.claude.md   # Claude Code / Codex rules (Opus High defaults)
first-party/README.md        # legacy pointer → skills/
manifest.json                # allowlist + upstream pins (paths → skills/…)
vendor/codex/                # snapshots without public upstream
scripts/install.sh           # global Claude/Codex/~/.agents from skills/ + vendor
scripts/link-project.sh      # per-project symlinks → .claude/skills + .agents/skills ONLY
scripts/update-project.sh    # refresh project links + re-copy rules templates
scripts/update-upstream.sh
scripts/refresh-codex-vendor.sh
```
