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

```bash
brew install bun
bun add -g simfleet@0.1.1      # or: bunx simfleet@0.1.1 <command>
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
the background from that project. Otherwise use the raw device path from the
`argent-ios-simulator-setup` or `argent-android-emulator-setup` skill.

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
  when you are done. `--stock` only skips auto-slim, so for a stock baseline use `sim restore` or
  `emu restore`. After `emu restore`, wait about 30 s and let adb sync before shutdown, or the restore
  is lost.
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
- **Stay under the host's simulator cap.** Run the host's health check from [Pick a host](../amillez-mode/references/orca-launch.md#pick-a-host) before
  `sim boot` or `emu boot`. When `ios_slots_free` or `android_slots_free` is a number, boot that kind
  of device only while it is above 0. `null` means the host has no cap for that kind, as for iOS on
  `agent-m1`. The counts include devices outside the fleet, such as Agustín's on the M4. Every host
  allows one Android emulator, so also check `simfleet emu list` and reuse a running one or wait.
  Don't boot a device or run `native ensure` while `status` is `blocked`, meaning free disk is below
  the host's floor. Ping Ben with its JSON line and wait. Policy source is [agent-use-policy §12](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#12-orca-hosts-and-resource-limits).
- **Slim on every host.** `agent-m1` and the M4 both run slim devices, per the slim-by-default rule
  above. Measured on 2026-10-25, an iOS simulator takes 4.0 to 4.4 GB of host memory stock and 1.0 to
  1.1 GB slim. An Android cold boot takes 4.2 GB stock and 3.2 to 3.7 GB slim. Android slim helps only
  when applied from boot. Slimming a running emulator saved nothing on `agent-m1`. Measure with
  `simslim measure` or `avdslim measure`, never summed RSS.
- **`avdslim tune-avd --help` is not read-only.** It applies the tune and purges the AVD's snapshots
  instead of printing help, so never run it to read usage.
- **simfleet outranks Argent's installer rules.** simfleet claims and the `xcrun simctl` operations this
  skill names, run only on devices you claimed (or booted, with the server down), win over Argent's
  "prefer running devices" and "never use `xcrun simctl`". See the Argent trigger in
  [amillez-mode](../amillez-mode/SKILL.md#non-negotiables).
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

After an Android lane or Android native build, run `./gradlew --stop` in the project's `android/`
directory and kill any of the job's daemons that `pgrep -fl 'GradleDaemon|KotlinCompileDaemon'` still
lists. Policy source is [agent-use-policy §12](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#12-orca-hosts-and-resource-limits).

## Report

State the lane ID, worktree and branch, device, environment and mode, bundle ID, Metro port and health
(or embedded delivery), whether the device is slim or stock, whether the native artifact was reused or
rebuilt, and the Argent evidence of the feature itself.
