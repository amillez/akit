### Authoring or modifying a skill

**You own the skill's voice.** Skills live in `amillez/akit`.

1. Work from a worktree of `amillez/akit` per [Opening a PR](opening-a-pr.md). A amillez skill is a directory under `skills/<name>/` with a `SKILL.md` and only the files it links (`references/`, `scripts/`, templates).
2. Write `SKILL.md` with YAML frontmatter holding `name` (matches the directory) and `description` (what it does and when to use it, since the description is what triggers the skill). Omit `disable-model-invocation` unless launch prompts must name the skill explicitly, and say so in the README row.
3. Wire a new skill into the install. The install scripts copy every directory under `skills/` except the mobile ones for `--groups core`, so add it to `firstParty` in `manifest.json` with its group and to the README group and allowlist tables. A mobile skill also goes in `MOBILE_AMILLEZ_SKILLS` in `scripts/install.sh`, and `./scripts/test-install.sh` fails until the two match. A ported skill also carries its upstream pin, license, and local changes in its own `UPSTREAM.md`.
4. Validate the skill. Frontmatter has `name` and `description`, referenced files exist, `./scripts/check-links.sh` passes, scripts keep their exec bit and pass `bash -n`, and `./scripts/test-install.sh` passes, which installs every amillez skill into a throwaway `HOME`.
5. Test cases if structural. Skip if subjective.
6. Run [Opening a PR](opening-a-pr.md). One skill change per PR.

When in doubt, delete. Keep only prose that changes a decision. Tell it to do the thing and skip the reason. Explain only when the rule is confusing without one. Match tone to scope. Point at structural sources (types, READMEs, config) per [Encode Lessons in Structure](../principles/encode-lessons-in-structure.md). Delegate to other skills by path. Don't restate. A workflow you keep hitting but isn't captured → propose a new skill.

**Reply:** summary of the skill, key design decisions, validation notes, and the PR link.
