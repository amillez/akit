# simfleet upstream

`simfleet` is our port of the agent skill that ships with the simfleet CLI. It is a mobile-group skill. The CLI itself is a host dependency and is not vendored here.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/entropyconquers/simfleet |
| Path | `skills/simfleet/` (`SKILL.md`, `references/api.md`) |
| Pinned commit | `be2bb055559ed16f09aedf34a36e53cc1e9385ac` (2026-09-29 04:26 +05:30) |
| Version | simfleet `0.1.1` (`package.json`, npm `simfleet@0.1.1`) |
| License | MIT, Copyright (c) 2026 Vishesh Raheja. Full text in [`LICENSE-simfleet`](LICENSE-simfleet), copied byte-for-byte from `LICENSE`. |

Attribution: the rules, the lane recipe, and `references/api.md` are Vishesh Raheja's work under MIT. Keep `LICENSE-simfleet` next to them.

## Local changes

1. **`references/api.md`** is verbatim.
2. **Frontmatter.** The description also triggers when `simfleet serve` answers on the host, lists restore and shutdown, and says Argent drives proof.
3. **Setup.** Adds `brew install bun` and a server liveness check (`/api/v1/capabilities`). When the server is down, start it only for a project with `.sim-fleet/project.json`, else fall back to the Argent setup skills.
4. **Slim and stock.** Upstream allows stock only on explicit request. Ours also allows it when the feature under test needs what slim disables (Play Services, Maps, telephony, push, StoreKit, and the rest), and names the direct `simslim off` and `avdslim off` fallbacks.
5. **Claims.** Names `SIMFLEET_AGENT` and `SIMFLEET_SESSION_ID`, which `src/cli.ts` reads before the Claude Code and Codex session variables.
6. **Drive.** Upstream's "Drive a device" section (`sim ui`, `tap`, `swipe`, and the Android equivalents) is replaced by "Drive and prove with Argent". The Android addressing notes move into the lane section.
7. **Stop.** Adds stopping a server you started and the raw teardown when the server is down.
8. **Style.** Em dashes and slash pairs rewritten per the `unslop` skill. Otherwise the wording stays upstream.
9. **Install wiring.** `manifest.json` lists `simfleet` in `amillez` with group `mobile`. `scripts/install.sh` holds the matching `MOBILE_AMILLEZ_SKILLS` entry and skips it for `--groups core`.
