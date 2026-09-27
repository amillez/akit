# maintain-verification-skill upstream

`maintain-verification-skill` is our port of poteto's `maintain-verification-skill` skill from pstack.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/maintain-verification-skill/SKILL.md` |
| Compared against | `ecc249f1e306fc64ddf83c7bed16cacf7c2239db` (pstack `0.15.5`) |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the maintain pass (source wave, live pass, triage, ship or stop) is poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to it.

## Local changes

1. **Target search.** `.claude/skills/verify-*/` and `.agents/skills/verify-*/`, never `.cursor/skills/`.
2. **Expo, React Native, and visual proof.** Drive with Argent. Visual evidence goes to the `media` branch and gets a GPT 6 Luna Max verify before a feature counts as verified. The live pass tears down simulators, emulators, and Metro or dev servers it started.
3. **App CLI check** (pairs with `create-verification-skill` local change 4). The live pass first checks the app CLI's `--help` and one `--dry-run` per destructive command. Failures are harness gaps, and the CLI is in edit scope.
4. **Skill text only.** `SKILL.md` names no host and carries no attribution or long dashes. Attribution lives here.
