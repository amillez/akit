# create-verification-skill upstream

`create-verification-skill` is our port of poteto's `create-verification-skill` skill from pstack.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/create-verification-skill/` (`SKILL.md`, `references/feature-map-example/`) |
| Compared against | `c742dd61706fbacc1b95f1a20b7b988cf096ce6c` (pstack `0.15.36`). `SKILL.md` last changed in `c49b37a2c0e7bede60a71ad7322e3f12c337a3da` (2026-10-12), whose readiness rules are ported. `references/feature-map-example/` is byte-identical at that commit. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the generator workflow, proof standards, and the feature map example are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Output location.** `.claude/skills/verify-<app>/` and `.agents/skills/verify-<app>/`, never `.cursor/skills/`.
2. **Expo and React Native.** Drive and launch with Argent, on an iOS 26 simulator by default for iOS, since iOS 18 has no liquid glass. For them, upstream's empty data dir means a fresh install or cleared app data, and ready means an Argent `await-ui-element` sees a seeded label.
3. **Visual proof.** Screenshots and video stay out of git and go in the PR's `review-guide` Orca artifact. Each asset gets an inspected pass or fail against the feature's end state. A separate verifier is optional and runs with the model unset.
4. **App CLI** (from poteto's "The Complete Guide to pstack Pt. 1", https://x.com/poteto/status/2094457600259842065). The generated skill ships one agent-friendly repo CLI for dev setup, seeding, test users and auth, reset, and opening a feature, with subcommands, JSON output, `--dry-run` on destructive commands, actionable errors, and rich `--help`. For Expo and React Native it covers only the app layer, since Argent drives the device. Step 4 proves `--help` and one `--dry-run`.
5. **Maintenance cadence.** Step 5 proposes a weekly scheduled routine running `/maintain-verification-skill` instead of suggesting a cadence only on request.
6. **Skill text only.** `SKILL.md` names no host and carries no attribution or long dashes. Attribution lives here.
7. **Orca host limits.** The Launch section links [agent-use-policy §12](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#12-orca-hosts-and-resource-limits) before a device boot or native build on whichever Orca host runs the session: the host's simulator cap and free-disk floor from [Pick a host](../amillez-mode/references/orca-launch.md#pick-a-host), and `./gradlew --stop` after an Android run. The policy text stays in the policy.
