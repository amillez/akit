---
name: create-verification-skill
description: >-
  Generate a project-local verify-<app> skill that drives the app the way a
  user does (Launch, Doctor, Drive, Evidence, Cleanup, an agent-friendly app
  CLI, and a feature map). Use for /create-verification-skill or when a project
  has no scripted way to prove UI, CLI, or service behavior.
disable-model-invocation: true
---
# Create a verification skill

Every serious project needs a scripted way to drive the real app and prove behavior: launch it, exercise a feature the way a user would, and capture evidence. This skill generates that as a project-local skill tailored to the repo. You write the generator's output for the next agent, not for a human: it will be read cold, mid-task, by an agent that has never seen the app.

## Output location

Write the generated skill under the project, in `.claude/skills/verify-<app>/` for Claude Code and `.agents/skills/verify-<app>/` for Codex. Write both when the project uses both agents. One is enough when it uses only one.

## 1. Interview the repo, not the user

Answer these from the codebase and only ask the user what you cannot observe:

- **Surface:** what does a user actually touch? A web UI, a CLI/TUI, a desktop app, an API, a mobile app, a library? A repo can have several; pick the primary one and note the rest.
- **Run:** how does the app start locally? Prefer the repo's own documented dev command (package scripts, Makefile, README quickstart). Note ports, env vars, seed data, auth, test users, and any staging backend. List the dev chores an agent would otherwise re-derive with throwaway scripts, since those become the app CLI.
- **Drive:** how can an agent interact with it programmatically? Existing harnesses first (Playwright/Cypress specs, expect scripts, PTY helpers, curl-able endpoints, a debug port). Only then pick a generic recipe: browser/CDP for web and Electron, a tmux/PTY harness for CLI/TUI, plain HTTP for services. **Expo / React Native:** use **Argent** (CLI plus MCP with a provisioned simulator or emulator); skills alone are not enough.
- **Observe:** what evidence can be captured? Screenshots, terminal transcripts, response bodies, logs, exit codes, DB state.
- **Isolate:** can two instances run side by side (ports, data dirs, profiles)? If not, say so in the generated skill: refusing to double-drive a shared instance beats corrupting the user's session.

If the checkout doesn't build or start as-is, fix that first (or report it precisely) before generating; a skill written against a broken base teaches wrong steps. When an irrelevant missing asset blocks startup (a static dir the API never serves, a sample config), the generated skill may create it, clearly marked as verification scaffolding, and remove it in cleanup.

## 2. Generate the skill

Write `verify-<app>/SKILL.md` at the [output location](#output-location) with YAML frontmatter (`name: verify-<app>` and a `description` that names the app, the surface, and when to reach for it; without frontmatter the skill never registers) and these sections, each grounded in what the interview actually found (no placeholders left):

- **Launch:** the exact command that starts the app for verification, and how to tell it's ready (a log line, a port answering, a prompt). Include teardown. For a short-lived CLI or TUI there is no server to keep alive: launch means build the binary (or install deps) once, then start each drive in its own isolated PTY or tmux session. For Expo/RN, launch via Argent simulator/emulator setup, or via a `simfleet` lane when the host runs `simfleet serve` (the `simfleet` skill).
- **Doctor:** one read-only check that answers "is this instance worth driving?" (process up, right version/build, port owned by us, auth valid). An agent runs this first whenever anything looks off.
- **Drive:** the harness recipe with real selectors/commands from this repo, not examples. Prefer stable handles (ARIA labels, data attributes, prompt strings, route paths) over coordinates and tab order. Expo/RN: Argent test-ui-flow / screenshot recipes.
- **Evidence:** what to capture for a proof and where it goes. State the proof standards: exercise the real user path, not internal setters or test-only endpoints; capture the action and the resulting state, not just the final screen; verify side effects (files written, rows inserted, messages sent) alongside what's visible; mocks only where a production boundary already isolates the external system. When the safe path is a dry-run or test mode, verify what it actually skips by observing (files, network, git refs) rather than trusting its name: some dry-runs still touch the network or open a browser. **Visual proof (screenshots/videos):** host on the repo's `media` branch (never the PR branch); inspect with a **Luna Max** verifier per [agent-proof-feedback-loop](https://github.com/amillez/ai-eng-practices/blob/main/playbooks/agent-proof-feedback-loop.md). Non-visual proof (logs, exit codes, traces) stays with the coding agent.
- **Cleanup:** how to tear down instances the run created. Never kill by process name; kill what you started. Cleanup removes instances and scratch state, never the evidence: proof artifacts survive the teardown, in a location the skill names. Tear down sims/emulators and dev servers the verification run started.
- **App CLI:** one small repo CLI (the feature map example's `control-notes` is the shape) that scripts the dev chores an agent would otherwise re-derive: bring up the dev environment the same way every time, seed a dev database or fixture state, create or log in test users against a local or staging backend, reset state, and open a mapped feature directly by route, deep link, or command. Wrap commands the repo already has instead of duplicating them. Shape it for agents:
  - subcommands that disclose functionality gradually instead of one flat flag list;
  - machine-readable output (JSON by default or behind `--json`);
  - `--dry-run` on every command with destructive side effects;
  - errors that say what to do instead, not just what failed;
  - rich `--help` on the CLI and on every subcommand.

  For Expo and React Native, Argent drives the device (taps, screenshots, recordings, profiling), so the CLI covers only the app layer: seed, test auth, reset, and open a feature by deep link. When the repo already has an equivalent, name it in the skill instead of writing a second one.
- **Helpers:** any script the skill ships, the app CLI included, is executable and its invocation is shown in the skill body. A helper the reader has to reverse-engineer is not a helper.

## 3. Seed the feature map

Create `verify-<app>/features/README.md` plus one file per user-facing feature you can identify (aim for the top 3-5 to start, from routes, commands, menus, or docs), under the same skill directory. Follow the shape in `references/feature-map-example/` (shipped beside this skill), with a README index and one file per feature. Each file answers, from the user's point of view: what the feature is, how to reach it, how to drive it with the harness, and what observable end state proves it works. The four H2s are `Sub-features`, `How to get to it (user POV)`, `Driving it with <harness>`, and `Gotchas`. The map is the repo's maintained verification source; a proof that drives one convenient entry point is incomplete when the map lists others.

## 4. Prove the generated skill before handing it over

Run its own instructions end to end once: run the app CLI's `--help` and one `--dry-run` of a destructive command, then launch, doctor, drive ONE mapped feature (one is enough; the map exists so later runs can cover the rest), capture evidence, clean up. After cleanup, confirm the evidence still exists at the named location. A cleanup that eats the proof fails this step. For visual evidence, confirm it is on the `media` branch and that Luna Max verify was applied (or note why visual verify was skipped). Fix what fails, and run the generated cleanup after every failed iteration too, so broken attempts don't strand processes and ports. A generated skill that was never executed is a draft, not a deliverable.

## 5. Offer the maintenance loop

Point the user at `/maintain-verification-skill` for keeping the map, harness, and app CLI honest as the app changes. Propose a weekly scheduled routine that runs it against this repo and opens a PR only when the outcome is `changed`. Offer it; don't set it up unasked.
