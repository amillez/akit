# agent-skills

Allowlisted engineering skills for **agent-m1** (Claude Code + Codex) and the daily driver.

Playbooks / *when to use* policy live in [`amillez/ai-eng-practices`](https://github.com/amillez/ai-eng-practices). This repo holds **skill bodies** + install/update scripts so we do not hand-duplicate folders on every machine.

## Allowlist

| Skill | Source | When |
| --- | --- | --- |
| All Argent `argent-*` | `software-mansion/argent` (pinned tag in `manifest.json`) | Skill description |
| `animate-expo` | `emilkowalski/skills` | Building animations |
| `apple-design` | `emilkowalski/skills` | Building UIs |
| `grill-me` | `mattpocock/skills` | Stress-test a plan before build |
| `expo-native-ui` | `expo/skills` | Building native UI |
| `expo-ui` | `expo/skills` | Building native UI |
| `expo-dev-client` | `expo/skills` | Build and distribute Expo development clients locally or via TestFlight for internal testing. For production TestFlight releases and store submission, use `eas-app-stores`. |
| `orchestrate-agents` | **first-party** | Fan out large work into parallel isolated prompts (Claude/Codex/mixed) |
| Codex native set (`api-design`, `build-nitro-modules`, `cpp`, `kotlin`, `swift`, `react-native-mmkv`, `react-native-nitro-fetch`, `react-native-vision-camera`) | **vendor snapshot** (no public skills-lock upstream) | Building native / Nitro modules |

Excluded for now: `autoreview`, Superset pack, Orca orchestration, other design/planning skills.

## Install on a machine

```bash
git clone git@github.com:amillez/agent-skills.git ~/agent-work/agent-skills
cd ~/agent-work/agent-skills
./scripts/install.sh
```

Also install the **Argent CLI** on agent hosts (skills alone are not enough):

```bash
npm install -g @swmansion/argent@0.25.0
argent init -y --no-telemetry --global
```

## Keeping skills up to date

Upstream packs (Argent, Emil, Matt, Expo) are managed by the [`skills`](https://www.npmjs.com/package/skills) CLI — same tool as `npx skills add`.

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

4. **First-party** (`orchestrate-agents`) — edit in this repo, commit, `git pull` + re-run the first-party copy section of `install.sh` (or full install).

5. **Lockfile** — after installs, `~/.agents/.skill-lock.json` records source URLs/hashes for upstream packs. Prefer that + this repo’s `manifest.json` over ad-hoc copies.

## Layout

```
manifest.json          # allowlist + upstream pins
first-party/           # skills we own
vendor/codex/          # snapshots without public upstream
scripts/install.sh
scripts/update-upstream.sh
scripts/refresh-codex-vendor.sh
```
