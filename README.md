# akit

Allowlisted engineering skills for **Claude Code and Codex**.

Policy on when to use what lives in [`amillez/ai-eng-practices`](https://github.com/amillez/ai-eng-practices). This repo holds the skill bodies, the model rules template, and the install scripts, so no device keeps hand-copied skill folders.

## Install model

| Pack | Where it lives | How |
| --- | --- | --- |
| **Amillez plugin** (amillez skills, model rules, allowlisted upstream packs) | **Device user root** | `./scripts/install.sh` → `~/.claude/skills`, `~/.agents/skills`; rules → `~/.claude/rules/amillez-models.md`, `~/.agents/rules/amillez-models.md`; stamp → `~/.amillez-plugin.json` |
| **Project skills** (e.g. `verify-*`) | **The project repo** | `.claude/skills/<name>/` and `.agents/skills/<name>/`, committed with the project |

The install scripts never write into project trees. A project may also commit copies of selected stack skills under `.claude/skills/` and `.agents/skills/` as a mirror for teammates.

## Install

### 1. Clone this repo (or pull latest)

```bash
git clone git@github.com:amillez/akit.git ~/agent-work/akit
# or, if already cloned:
cd ~/agent-work/akit && git pull
```

### 2. Install at user root

```bash
cd ~/agent-work/akit
./scripts/install.sh                 # default: core + mobile
# ./scripts/install.sh --groups core           # core only
# ./scripts/install.sh --groups mobile         # core still included + mobile
# ./scripts/install.sh --groups core,mobile    # same as default
```

`install.sh` adds the allowlisted upstream packs with `npx skills add`, copies the amillez skills under `skills/` for the chosen groups into `~/.agents/skills` and `~/.claude/skills`, copies `templates/models.md` to the user rules dirs, and writes `~/.amillez-plugin.json` (and `~/.agents/amillez-plugin.json`).

**Groups** (see `manifest.json` `groups` and the per-entry `group` tags):

| Group | Always? | Contents |
| --- | --- | --- |
| `core` | **yes** (even with `--groups mobile`) | `amillez-mode`, `grill-me`, `grilling`, `orchestrate-agents`, `create-verification-skill`, `maintain-verification-skill`, `setup-amillez-models`, `typescript-best-practices`, `correct`, `blast-radius` |
| `mobile` | no | Argent, `animate-expo`, `apple-design`, `review-animations`, `expo-dev-client`, `expo-upgrade`, `react-native-best-practices`, `uniwind`, Margelo Nitro modules, `simfleet` |

Default is **core+mobile**. `--groups core` skips mobile.

Mobile work also needs the **Argent CLI** on the device (skills alone are not enough):

```bash
npm install -g @swmansion/argent@0.25.0
argent init -y --no-telemetry --global
```

The `simfleet` skill needs the **simfleet CLI** and its device tools. Skip this block on a host that does not run simfleet. The skill falls back to the Argent setup skills when `simfleet serve` is not up.

```bash
brew install bun
bun add -g simfleet@0.1.1
brew install mobai-app/tap/simslim baguette watchman
brew tap kdbhalala/avdslim https://github.com/kdbhalala/avdslim.git && brew install avdslim scrcpy
```

### 3. Ensure the install before coding

Run this before every coding session. Bots and agents run it automatically per the [`ai-eng-practices`](https://github.com/amillez/ai-eng-practices) policy.

```bash
cd ~/agent-work/akit
./scripts/ensure-install.sh
```

- The pack counts as installed when the stamp exists and every amillez skill the chosen groups install (`install.sh --list-skills`) is in both `~/.claude/skills` and `~/.agents/skills`.
- If the stamp is missing, it runs `update-install.sh` and prints `amillez plugin: installed`. If a amillez skill is missing, it refreshes and prints `amillez plugin: updated`. Otherwise it prints `amillez plugin: already present`.
- `--force` refreshes even when the pack is present. `--groups` works as in `install.sh`.

### Scripts

- **`ensure-install.sh`**. The required entry point before coding. It is idempotent. It detects the pack and installs or refreshes it at user root.
- **`update-install.sh`**. Refreshes user-root skills, copies `templates/models.md` to `~/.claude/rules/amillez-models.md` and `~/.agents/rules/amillez-models.md`, and rewrites the stamp. `--skip-upstream` skips the npx packs. `--skip-skills` refreshes only the rules and the stamp.
- **`install.sh`**. Full install: upstream packs, amillez skills, user rules, and the stamp. `--skip-upstream` skips the npx packs.
- **`test-install.sh`**. Runs the three install scripts against a temporary `HOME` with a stub `npx`. Run it after changing any install script.
- **`check-links.sh`**. Checks relative Markdown links and their anchors.
- **`update-upstream.sh`**. See [Keeping skills up to date](#keeping-skills-up-to-date).

## Allowlist

Grouped as **core** and **mobile** in `manifest.json`, selectable with `--groups` on `install.sh`, `ensure-install.sh`, and `update-install.sh`.

| Skill | Group | Source | When |
| --- | --- | --- | --- |
| All Argent `argent-*` | mobile | `software-mansion/argent` (pinned tag in `manifest.json`) | Skill description |
| `animate-expo` | mobile | `emilkowalski/skills` | Building animations |
| `apple-design` | mobile | `emilkowalski/skills` | Building UIs |
| `review-animations` | mobile | `emilkowalski/skills` | Reviewing or critiquing animation and motion (Emil craft bar). Upstream sets `disable-model-invocation: true`, so the model never invokes it on its own. Launch prompts name it for critique passes. |
| `grill-me` | core | `mattpocock/skills` | Stress-test a plan before build |
| `grilling` | core | `mattpocock/skills` | Holds the `grill-me` content. Upstream `grill-me` only forwards to it. |
| `expo-dev-client` | mobile | `expo/skills` | Build and distribute Expo development clients locally or via TestFlight for internal testing. For production TestFlight releases and store submission, use `eas-app-stores`. |
| `expo-upgrade` | mobile | `expo/skills` | Skill description (Expo SDK upgrades, dependency conflicts, deprecated packages, cache cleanup) |
| `react-native-best-practices` | mobile | `software-mansion-labs/skills` | Skill description, when writing, reviewing, or debugging any React Native or Expo code |
| `uniwind` | mobile | `uni-stack/uniwind` | Skill description, when building or debugging Uniwind className styling in RN |
| `amillez-mode` | core | **amillez** (pstack `poteto-mode` port, MIT; see `skills/amillez-mode/UPSTREAM.md`) | **Required** working mode for every coding agent (single agent or Orca worker). Launch prompts name it explicitly. |
| `orchestrate-agents` | core | **amillez** (brief template and retry rules adapted from pstack, MIT; see `skills/orchestrate-agents/UPSTREAM.md`) | Size gate, then Orca with an Opus 5.5 xHigh coordinator for large work. Worker briefs name `amillez-mode`, which every invoked coding agent loads. |
| `create-verification-skill` | core | **amillez** (pstack port, MIT; see `skills/create-verification-skill/UPSTREAM.md`) | Generate a project-local `verify-<app>` skill: Launch, Doctor, Drive, Evidence, Cleanup, an agent-friendly app CLI (dev setup, seeding, test users, reset, open a feature), and a feature map |
| `maintain-verification-skill` | core | **amillez** (pstack port, MIT; see `skills/maintain-verification-skill/UPSTREAM.md`) | Keep a project `verify-<app>` skill, its feature map, and its app CLI honest |
| `setup-amillez-models` | core | **amillez** | Pick the session's model lane from the policy and install or update the user-level model rules (`templates/models.md`) |
| `typescript-best-practices` | core | **amillez** (pstack port, MIT; see `skills/typescript-best-practices/UPSTREAM.md`) | Skill description, when reading, writing, or reviewing any `.ts` or `.tsx` file. Claude Code also scopes it with `paths`. |
| `correct` | core | **amillez** (pstack port, MIT; see `skills/correct/UPSTREAM.md`) | `/correct`, a standalone skill that holds the whole procedure for making each mistake agents repeat in a repo impossible. Sets `disable-model-invocation: true`, so the model never invokes it on its own. amillez-mode's repeated-correction trigger names it. |
| `blast-radius` | core | **amillez** (pstack port, MIT; see `skills/blast-radius/UPSTREAM.md`) | `/blast-radius`, a standalone skill that holds the whole procedure for finding what a change could break beyond the diff and proving the one fact it is safe because of. Sets `disable-model-invocation: true`, so the model never invokes it on its own. amillez-mode's untrusted-diff trigger names it. |
| Nitro modules set (`api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`) | mobile | `margelo/react-native-skills` | Building native or Nitro modules |
| `simfleet` | mobile | **amillez** (`entropyconquers/simfleet` port, MIT; see `skills/simfleet/UPSTREAM.md`) | Boot, slim, restore, claim, and shut down simulators and emulators through simfleet, and run worktree lanes with leased Metro ports. Argent still drives proof. Needs the simfleet CLI (see [Install](#2-install-at-user-root)). |

Not in the pack: `autoreview`, the Superset pack, other design and planning skills, and `expo-native-ui`. Orca's own skills (`orca-cli`, `orchestration`) come from `orca skills install` on the coordinator device (see `orchestrate-agents`).

## Model rule template

| Template | Destination |
| --- | --- |
| `templates/models.md` | `~/.claude/rules/amillez-models.md` and `~/.agents/rules/amillez-models.md` (user level) |

Defaults: super defined → **GPT 6 Luna Max** (Codex); general code and UI → **Opus 5.5 High** (Claude Code), or **GPT 6.1 Sol** (xHigh general, High UI, Codex) when Claude Code usage is above 70%; Orca coordinator → **Opus 5.5 xHigh**; large non-orchestration reasoning → **Fable 5.1 Medium**, then High or xHigh. Workers pick per task from the policy. `/setup-amillez-models`, `update-install.sh`, and `install.sh` refresh the user rules. Nothing writes project `.claude/rules/` or `.agents/rules/`.

## Keeping skills up to date

The [`skills`](https://www.npmjs.com/package/skills) CLI (the tool behind `npx skills add`) manages the upstream packs (Argent, Emil, Matt, Expo, Software Mansion Labs, Uniwind, Margelo).

1. **Routine refresh.** Pull the latest for globally installed skills that the CLI tracks:

   ```bash
   npx skills update -g -y
   ```

   Or: `./scripts/update-upstream.sh`

2. **Argent version bumps.** Pin the CLI and the skills tag together. Update the ref in `manifest.json` (`upstream[argent].ref`) and in `scripts/install.sh`, upgrade `@swmansion/argent`, then re-run `./scripts/install.sh`.

3. **Amillez** (every directory under `skills/`). Edit under `skills/` and commit. On each device, `git pull` and run `./scripts/update-install.sh --skip-upstream`. `ensure-install.sh` only adds missing skills, so it does not pick up edits to installed ones.

4. **Lockfile.** After installs, `~/.agents/.skill-lock.json` records source URLs and hashes for the upstream packs. Prefer it and this repo's `manifest.json` over ad hoc copies.

## Layout

```
amillez-plugin.json          # pack metadata
skills/                      # amillez skills, one directory each
templates/models.md          # Claude Code and Codex model rules → user rules dirs
manifest.json                # allowlist, groups, and upstream pins
scripts/install.sh           # user-root install: skills, user rules, stamp
scripts/ensure-install.sh    # required before coding: detect, then install or refresh
scripts/update-install.sh    # refresh user-root skills, rules, and stamp
scripts/test-install.sh      # sandboxed test of the three install scripts
scripts/check-links.sh       # relative Markdown link and anchor check
scripts/update-upstream.sh   # npx skills update for upstream packs
```
