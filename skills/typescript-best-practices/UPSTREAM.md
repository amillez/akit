# typescript-best-practices upstream

`typescript-best-practices` is our port of poteto's `typescript-best-practices` skill from pstack. It is a separate core skill so it can load on its own for TypeScript files. It grounds amillez-mode's type-system-discipline and boundary-discipline principles in TypeScript syntax.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/typescript-best-practices/` (`SKILL.md`, `references/patterns.md`) |
| Pinned commit | `ecc249f1e306fc64ddf83c7bed16cacf7c2239db` (2026-09-25 16:04 -07:00). Last checked against `origin/main` on 2026-09-27. |
| Version | pstack `0.15.5` |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The same pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit both together.

Attribution: the rule table and the code examples are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Frontmatter.** Kept `name` and `paths: ["**/*.ts", "**/*.tsx"]`. Claude Code honors `paths` and loads the skill automatically only for matching files. Codex reads only `name`, `description`, and `metadata`, so the description names what the skill covers and carries the `.ts`/`.tsx` trigger. Dropped `disable-model-invocation: true` so both tools can load it without a slash command.
2. **Principle links.** "the type-system-discipline principle skill" and "the boundary-discipline principle skill" → relative links into `../amillez-mode/principles/`. Both skills install as siblings under `~/.claude/skills/` and `~/.agents/skills/` (see `scripts/install.sh`), and amillez-mode is core, so the links resolve in the repo and after install.
3. **Scope and deference.** Added a Scope block. React Native and Expo library usage and typing defer to `react-native-best-practices` (mobile group), and public library API shape defers to the Codex vendor `api-design` skill when installed. Neither is linked, since the mobile group is optional.
4. **Rules dropped.** "Real tests" (overlaps amillez-mode's test-behavior-not-implementation and prove-it-works principles, linked instead) and "Structured telemetry" (generic logging advice, not TypeScript). Neither had a section in `patterns.md`.
5. **`patterns.md` trims.** Intro principle mentions → links. "No `as` casts" points back at the schema section first. "Boundary validation" drops the "don't re-validate deep" bullet (the boundary-discipline principle already says it) and the JSON-RPC mention, and adds the usual app boundaries (fetch, stored values, deep links, push payloads, native modules). "Persisted JSON" is kept as a fallback-branch rule. "Object args" hot paths add per-frame worklet callbacks. Everything else is verbatim.
6. **Back-link.** amillez-mode's type-system-discipline principle links this skill where it names it.

## Overlap check (2026-09-27)

- `software-mansion-labs/skills` `react-native-best-practices` at `e3f00cd` (2026-09-16) covers library APIs (Reanimated, gestures, worklets and threading, JSI, audio, SVG, on-device AI, rich text, worklets bundle mode). It has no general TypeScript type-discipline guidance. The only near touches are worklets' own type guards (`isSerializableRef`, `isSynchronizable`), which fall under library usage and defer there.
- Codex vendor `api-design` covers public library API shape, including literal and discriminated unions for option types and its own TS style rules. This skill defers to it for exported APIs. No rule here conflicts.
