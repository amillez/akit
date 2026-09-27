# create-verification-skill upstream

`create-verification-skill` is our port of poteto's `create-verification-skill` skill from pstack.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/create-verification-skill/` (`SKILL.md`, `references/feature-map-example/`) |
| Compared against | `ecc249f1e306fc64ddf83c7bed16cacf7c2239db` (pstack `0.15.5`). `references/feature-map-example/` is byte-identical at that commit. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the generator workflow, proof standards, and the feature map example are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Output location.** `.claude/skills/verify-<app>/` and `.agents/skills/verify-<app>/`, never `.cursor/skills/`.
2. **Expo and React Native.** Drive and launch with Argent.
3. **Visual proof.** Screenshots and video go to the repo's `media` branch with a GPT 6 Luna Max verify, per ai-eng-practices `agent-proof-feedback-loop`.
4. **App CLI** (from poteto's "The Complete Guide to pstack Pt. 1", https://x.com/poteto/status/2094457600259842065). The generated skill ships one agent-friendly repo CLI for dev setup, seeding, test users and auth, reset, and opening a feature, with subcommands, JSON output, `--dry-run` on destructive commands, actionable errors, and rich `--help`. For Expo and React Native it covers only the app layer, since Argent drives the device. Step 4 proves `--help` and one `--dry-run`.
5. **Maintenance cadence.** Step 5 proposes a weekly scheduled routine running `/maintain-verification-skill` instead of suggesting a cadence only on request.
6. **Skill text only.** `SKILL.md` names no host and carries no attribution or long dashes. Attribution lives here.
