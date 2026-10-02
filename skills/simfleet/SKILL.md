---
name: simfleet
description: >
  Operate a simfleet device fleet: slimmed iOS simulators and Android emulators, parallel React Native
  worktree lanes with leased Metro ports, the native build cache, and per-agent device claims. Use this
  skill whenever `simfleet serve` answers on the host or a project has `.sim-fleet/project.json`, and an
  agent needs to boot, slim, restore, claim, or shut down a simulator or emulator, run one or more
  worktrees on devices, allocate or inspect Metro ports, launch an environment or build variant, or
  diagnose simulator RAM. Also use it when the request only says "run this branch", "open the
  simulator", or "fix a Metro port collision". Argent still drives the UI and captures proof.
---

# simfleet

simfleet is one control plane for every simulator, emulator, Metro server, and lane on this Mac. The
browser dashboard and this CLI operate the same state. Never start a second dashboard, an unmanaged
Metro, or a device outside the fleet.

## Setup

simfleet governs only projects that have `.sim-fleet/project.json`. A project without that file uses the
raw Argent device path (`argent-ios-simulator-setup` or `argent-android-emulator-setup`) and picks Metro
ports with `lsof`, even while `simfleet serve` is up for another project. Do not probe a guessed port or
read another project's state.

```bash
brew install bun
bun add -g simfleet            # or: bunx simfleet <command>
simfleet version
simfleet serve                 # dashboard + API on http://127.0.0.1:8790, menu-bar icon
```

Host tools: `brew install mobai-app/tap/simslim baguette watchman` (iOS) and
`brew tap kdbhalala/avdslim https://github.com/kdbhalala/avdslim.git && brew install avdslim scrcpy`
plus the Android SDK (Android). Commands run from any checkout or worktree of a project with
`.sim-fleet/project.json`; simfleet resolves the main checkout. Set `SIM_FLEET_URL` only when the server
runs at another origin.

Every CLI command goes through the server. Check that it is up before relying on simfleet:

```bash
curl -sf http://127.0.0.1:8790/api/v1/capabilities >/dev/null && echo up
simfleet status                # host RAM, worktrees, lanes, Metros, simulators, emulators, agents
simfleet ports                 # environment port ranges and live leases
simfleet sim list | emu list | lane list | agents
```

If the server is down and the project has `.sim-fleet/project.json`, start `simfleet serve --no-tray` in
the background from that project. Otherwise use the raw device path.

Read [`references/api.md`](references/api.md) when the CLI lacks an operation or another program needs
the HTTP/WebSocket contract.

## Rules

- **Devices are slim by default.** Boot with `simfleet sim boot <udid>` or `simfleet emu boot <avd>`.
  Both apply and verify the slim profile. Do not boot fleet devices with `xcrun simctl boot`, Xcode,
  Android Studio, Argent `boot-device`, or another tool's boot command. The server auto-slims strays
  (Android live, iOS only in its first minutes, because SimSlim reboots).
- **Go stock when the task needs what slim disables.** Slim Android disables Play Services, Maps, the
  dialer, and telephony packages. Slim iOS disables push (`apsd`), StoreKit, Apple Pay, Spotlight, the
  Contacts and Photos pickers, and universal links. When the feature under test needs one of them, boot
  with `--stock`, or run `simfleet sim restore <udid>` or `simfleet emu restore <avd>` on a running
  device. With the server down, `simslim off <udid>` and `avdslim off` do the same. Run `slim` again
  when you are done.
- **Claim what you hold.** Every CLI call from a Claude Code or Codex session is attributed to the
  device it touches. Export `SIMFLEET_AGENT` (the bot or agent name) and `SIMFLEET_SESSION_ID` (your
  session or branch) so claims name you, and they are required when `claim` reports it could not detect
  the calling session. Run `simfleet claim <udid-or-avd> "what you are doing"` before a long task and
  `simfleet release <udid-or-avd>` when done. Never drive a device another live session has claimed
  (check `simfleet agents`).
- **Lanes own ports.** A debug lane leases its Metro port from the environment's range. Release lanes
  embed JS and have no Metro. Never pick ports by hand, hash branch names into ports, or kill an
  unknown Node or Metro process. Inspect `ports` and `status`, then stop the owning lane.
- **Bundle identifiers are stable native identities**, never worktree identities. Environments
  (development, staging, preprod, production) select runtime JS config and never force a native build.
- **JS-first.** For ordinary React Native changes, start a lane, wait for Metro, and launch. Build
  natively only when native inputs changed, and only through `native plan` and `native ensure`
  (fingerprinted, single-flight, shared across agents). Never run `expo run:ios`, CocoaPods, or Xcode
  directly.
- Work in existing worktrees. Create one only when asked, via `simfleet worktree create`.
- Stop only lanes you started.

## Run a worktree on a device

```bash
simfleet status && simfleet ports                          # 1. inspect ownership first
simfleet sim boot <udid>                                   # 2. or: simfleet emu boot <avd>
simfleet claim <udid> "testing checkout on feature-x"      # 3.
simfleet native plan <abs-worktree> debug <udid>           # 4. iOS: expect a cache hit for JS-only work
simfleet native ensure <abs-worktree> <udid> debug
simfleet lane start <abs-worktree> <udid-or-avd> [environment] [debug|release]   # 5.
simfleet lane launch <lane-id>                             # 6. waits for Metro health
simfleet lane open-url <lane-id> <path-or-url>             #    uses the mode's scheme
```

Lane creation fails rather than stealing a worktree, device, or occupied port. If launch reports Metro
not ready, read `simfleet lane log <lane-id>` and fix the actual Metro error while keeping the lease.

Parallel agents each own exactly one worktree, device, and lane. `native ensure` may be called
concurrently (one build, everyone reuses it).

Android devices are addressed by AVD name (the `emulator-5554` serial only exists while running).
Android lanes are debug-only. `lane launch` sets up `adb reverse` and opens the dev client, which must
already be installed.

## Drive and prove with Argent

simfleet boots, slims, claims, and runs lanes. Argent drives the UI and captures proof. After the lane
launches, pick the booted device from Argent `list-devices` and follow `argent-device-interact` and
`argent-test-ui-flow`. Metro health or a successful launch is not proof a feature works.

## Stop

With the server up, tear down through simfleet:

```bash
simfleet lane stop <lane-id>
simfleet release <udid-or-avd>
simfleet sim shutdown <udid> | simfleet emu shutdown <avd>     # only devices you booted
```

Stop `simfleet serve` if you started it. With the server down, use `xcrun simctl shutdown <udid>` and
`adb -s <serial> emu kill` for the devices you booted.

## Report

State the lane ID, worktree and branch, device, environment and mode, bundle ID, Metro port and health
(or embedded delivery), whether the device is slim or stock, whether the native artifact was reused or
rebuilt, and the Argent evidence of the feature itself.
