# create-formal-verification-skill upstream

`create-formal-verification-skill` is our port of poteto's `create-formal-verification-skill` skill from pstack. It pairs with [`maintain-formal-verification-skill`](../maintain-formal-verification-skill/UPSTREAM.md), which its hand-off names.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/create-formal-verification-skill/` (`SKILL.md`) |
| Compared against | `d457567332aa6989e753ea289f30ea2bfbc80bc0` (pstack `0.15.28`). `SKILL.md` last changed in `7b353f78f6ec193bdbe48ed8059444eb09b6878e` (2026-10-19), after `4382e687a50b8d2c5ce4d141d001186589cff8d5` added it and `6b78e9f4e46c75d1697d837e51f07c2692e60b24` added the TLA+ default and the no-verifier fallback. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the target choice, tool choice, quality bar, proof, and hand-off are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Output location.** `.claude/skills/<name>/` and `.agents/skills/<name>/`, never `.cursor/skills/`.
2. **Dependency age.** When the verification tool becomes a project dependency, its version follows the dependency-age rule in ai-eng-practices `agent-use-policy` §11, not the latest release.
3. **Skill text only.** `SKILL.md` names no host and carries no attribution or long dashes. Attribution lives here. Everything else is upstream text, frontmatter included, so it keeps `disable-model-invocation: true` and `/create-formal-verification-skill` loads it.
