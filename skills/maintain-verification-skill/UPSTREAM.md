# maintain-verification-skill upstream

`maintain-verification-skill` is our port of poteto's `maintain-verification-skill` skill from pstack.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/maintain-verification-skill/SKILL.md` |
| Compared against | `e73df471cd4bd918367e99f3dd9c51bd53ddf5f0` (pstack `0.15.32`). The file is unchanged upstream since `6714489fa233263f00e419f6cfc4759b07c81056` (2026-07-12). |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the maintain pass (source wave, live pass, triage, ship or stop) is poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to it.

## Local changes

1. **Target search.** `.claude/skills/verify-*/` and `.agents/skills/verify-*/`, never `.cursor/skills/`.
2. **Expo, React Native, and visual proof.** Drive with Argent. Visual evidence goes to the `media` branch and is inspected against the feature's end state before a feature counts as verified. A separate verifier is optional and runs with the model unset. The live pass tears down simulators, emulators, and Metro or dev servers it started.
3. **App CLI check** (pairs with `create-verification-skill` local change 4). The live pass first checks the app CLI's `--help` and one `--dry-run` per destructive command. Failures are harness gaps, and the CLI is in edit scope.
4. **Empty data dir.** The live pass launches from an empty data dir at least once per pass, and a ready signal that fires before the app is usable is a harness gap. Upstream added the readiness rule only to `create-verification-skill`. This line catches verify skills written before it.
5. **Skill text only.** `SKILL.md` names no host and carries no attribution or long dashes. Attribution lives here.
6. **Orca host limits** (pairs with `create-verification-skill` local change 7). The intro links [agent-use-policy §12](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#12-orca-hosts-and-resource-limits) before the live pass boots a device or starts a native build on whichever Orca host runs the session: the host's simulator cap and free-disk floor from [Pick a host](../amillez-mode/references/orca-launch.md#pick-a-host), and `./gradlew --stop` after an Android run. The policy text stays in the policy.
